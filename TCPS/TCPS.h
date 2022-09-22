
#ifndef  TCPS_H
#define  TCPS_H

#include <WS2tcpip.h>
#pragma comment(lib, "ws2_32.lib")


#include <assert.h>
#include <future>
#include <vector>
#include <map>

#define TCPS_MAGIC 0x53504354
#define TCPS_XOR_KEY 0x54435053
#define TCPS_SNOWFLAKE 0x54435053
#define SNOWFLAKE_NEXT(snowflake) ((snowflake ^ TCPS_XOR_KEY) + TCPS_MAGIC)

#define REQUEST_TIMEOUT_MS 10000
#define MAX_POLLER_CONNECTION 64
#define POLLER_REFRESH_INTERVAL 50
#define HEARTBEAT_INTERVAL 3000

namespace TCPS
{

	enum class NWSTATUS
	{
		OK,
		CONNECT_TIMEOUT,
		CONNECT_FAILED,
		SOCKET_FAILED,
		BIND_FAILED,
		LISTEN_FAILED,
		IOTCL_FAILED,
		DISCONNECT,
		INVALID_SNOWFLAKE,
		NO_HANDLER,
		NO_FAIL_HANDLER,
		DATA_CORRUPT,
	};

	enum class TCPSCOMMAND
	{
		USERDATA,
		HANDSHAKE,
		HEARTBEAT,
	};

	struct RequestQueuePacket;

	// sizeof(PACKET_HEADER) MUST BE inline of 4 bytes for the encryption to work!!!
	struct PACKET_HEADER
	{

	private:
		TCPSCOMMAND internalCmd;
		DWORD snowflake;
		DWORD response_snowflake;

		friend class Packet;
		friend class Client;
		friend class ServerPoller;
		friend class Server;

	public:
		int cmd;
		int size;

		PACKET_HEADER()
		{
			internalCmd = TCPSCOMMAND::USERDATA;
			snowflake = TCPS_SNOWFLAKE;
			response_snowflake = 0;
			cmd = 0;
			size = 0;
		}
	};


	class Packet;
	class Client;
	class ServerPoller;
	class Server;

	using PacketDoneHandler = std::function<void(Packet packet)>;
	using PacketFailHandler = std::function<void()>;
	typedef void RequestHandler(Client* client, Packet packet);

	// return true to accept the connection, false to reject
	typedef bool AcceptHandler(Client* client);
	typedef void DisconnectHandler(Client* client);
	typedef void PollerEventHandler(ServerPoller* poller, int index);
	typedef void ErrorHandler(Client* client, NWSTATUS status, LPVOID data);



	int InitTCPS();
	std::string NWStatusGetMessage(NWSTATUS status);
	int recv(SOCKET sock, void* buffer, int size, int flags);
	void EncryptData(LPVOID data, SIZE_T size, DWORD key);


	class Packet
	{
	private:
		PacketDoneHandler doneHandler = nullptr; // called when response packet arrived
		PacketFailHandler failHandler = nullptr; // called when fail to send or time out waiting

		Client* owner = nullptr; // owner of this packet

		PACKET_HEADER header; // contains info about the packet
		std::shared_ptr<BYTE[]> body; // contains the actual data

		Packet(Client* owner, TCPSCOMMAND internalCmd, int cmd = 0, int size = 0, LPVOID copy = 0);
		Packet(Client* owner, PACKET_HEADER header, LPVOID copy = nullptr);

		bool send();

		friend class Client;
		friend class Server;


	public:


		Packet(Client* owner = nullptr);
		Packet(Client* owner, int cmd);
		Packet(Client* owner, int cmd, std::string string);
		Packet(Client* owner, int cmd, int size, LPVOID copy);
		~Packet();

		bool request();
		bool response(int cmd);
		bool response(int cmd, std::string string);
		bool response(int cmd, int size, LPVOID copy);
		bool response(Packet& response);

		Packet& done(PacketDoneHandler&& handler);
		Packet& fail(PacketFailHandler&& handler);
		BYTE* data(size_t offset = 0);
		template <typename T>
		T read(size_t offset = 0)
		{
			return *(T*)(body.get() + offset);
		}
		PACKET_HEADER GetHeader();
		int cmd();
		int size();

	};

	class Client
	{
	private:
		std::atomic<DWORD> snowflake_recv = TCPS_SNOWFLAKE;
		std::atomic<DWORD> snowflake_send = TCPS_SNOWFLAKE;

		std::mutex mtxQueue;
		std::mutex mtxSend;

		std::map<DWORD, RequestQueuePacket> requestQueue;
		std::map<int, RequestHandler*> requestHandlers;

		DisconnectHandler* onDisconnectHandler = nullptr;
		ErrorHandler* errorHandler = nullptr;

		std::atomic<bool> isThreadAlive = false;

		std::thread* t_recv = nullptr;

		Server* owner = nullptr;

		SOCKET sock = INVALID_SOCKET;

		time_t lastHeartBeat = clock();
		std::string IPAddress = "";
		int Port = 0;

		void threadRecv();
		void cleanup();
		void IntervalCheck();

		NWSTATUS RecvPacket(Packet* packet);
		NWSTATUS ProcessPacket(Packet* packet);
		NWSTATUS handleError(NWSTATUS status, LPVOID data);

		Packet packet(TCPSCOMMAND internalCmd, int cmd = 0, int size = 0, LPVOID copy = 0);

		friend class Packet;
		friend class Server;
		friend class ServerPoller;

	public:

		Client(std::string IPAddress, int Port);
		Client(SOCKET sock);
		~Client();

		NWSTATUS connect(int timeout = 5000);
		void disconnect();

		void AddHandler(int cmd, RequestHandler* handler);
		void RemoveHandler(int cmd);
		void AddErrorHandler(ErrorHandler* handler);
		void onDisconnect(DisconnectHandler* handler);

		Packet packet(int cmd);
		Packet packet(int cmd, std::string string);
		Packet packet(int cmd, int size, LPVOID copy);
		Packet packet(int cmd, int size, const char* copy);

		std::string ip()
		{
			return IPAddress;
		}

		int port()
		{
			return Port;
		}

		SOCKET socket()
		{
			return sock;
		}

		bool isConnecting()
		{
			return isThreadAlive;
		}
	};

	class ServerPoller
	{
	private:

		std::vector<SOCKET> waitingConnections;
		std::vector<WSAPOLLFD> connections;

		std::map<SOCKET, std::shared_ptr<Client>> clients;

		std::thread mainThread;
		std::mutex mtxConnection;

		Server* owner;

		void PollerThread();
		void RemoveConnection(SOCKET socket); // only call this when not polling

		friend class Server;

	public:
		ServerPoller(Server* owner, SOCKET firstSocket);
		void AddConnection(SOCKET socket);
		int ConnectionsSize()
		{
			return connections.size();
		}

	};

	class Server
	{
	private:
		std::thread t_accept;
		SOCKET listening = INVALID_SOCKET;

		int Port;

		// Callback handler for requests
		std::map<int, RequestHandler*> requestHandlers;

		// mutex for clients read and write
		std::mutex mtxPollers;

		DisconnectHandler* onDisconnectHandler = nullptr;
		AcceptHandler* onAcceptHandler = nullptr;
		ErrorHandler* errorHandler = nullptr;
		PollerEventHandler* onPollerCreationHandler = nullptr;
		PollerEventHandler* onPollerDestructionHandler = nullptr;

		std::vector<std::shared_ptr<ServerPoller>> pollers;

		friend class Packet;
		friend class Client;
		friend class ServerPoller;

		void threadAccept();
		void RemovePoller();
		void AddPoller(SOCKET sock);

	public:

		Server(int Port);
		~Server();

		NWSTATUS start(bool newThread = false);

		void AddHandler(int cmd, RequestHandler* handler);
		void RemoveHandler(int cmd);
		void AddErrorHandler(ErrorHandler* handler);
		void onDisconnect(DisconnectHandler* handler);
		void onAccept(AcceptHandler* handler);
		void onPollerCreation(PollerEventHandler* handler);
		void onPollerDestruction(PollerEventHandler* handler);

	};

	struct RequestQueuePacket
	{
		time_t timeInit;
		PacketDoneHandler doneHandler;
		PacketFailHandler failHandler;
		Packet packet;

		RequestQueuePacket()
		{
			timeInit = 0;
			doneHandler = nullptr;
			failHandler = nullptr;
		}
	};



}


#endif