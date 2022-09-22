#include "TCPS.h"

namespace TCPS
{
	int InitTCPS()
	{
		static int wsResult = NULL;
		static bool init = false;

		if (!init)
		{
			WSAData data;
			WORD ver = MAKEWORD(2, 2);
			wsResult = WSAStartup(ver, &data);
		}

		return wsResult;
	}

	std::string NWStatusGetMessage(NWSTATUS status)
	{
		static std::map<NWSTATUS, std::string> msgTable =
		{
			{NWSTATUS::OK, "OK"},
			{NWSTATUS::CONNECT_TIMEOUT, "CONNECT_TIMEOUT"},
			{NWSTATUS::CONNECT_FAILED, "CONNECT_FAILED"},
			{NWSTATUS::SOCKET_FAILED, "SOCKET_FAILED"},
			{NWSTATUS::BIND_FAILED, "BIND_FAILED"},
			{NWSTATUS::LISTEN_FAILED, "LISTEN_FAILED"},
			{NWSTATUS::IOTCL_FAILED, "IOTCL_FAILED"},
			{NWSTATUS::DISCONNECT, "DISCONNECT"},
			{NWSTATUS::INVALID_SNOWFLAKE, "INVALID_SNOWFLAKE"},
			{NWSTATUS::NO_HANDLER, "NO_HANDLER"},
			{NWSTATUS::NO_FAIL_HANDLER, "NO_FAIL_HANDLER"},
			{NWSTATUS::DATA_CORRUPT, "DATA_CORRUPT"},
		};

		auto find = msgTable.find(status);
		if (find == msgTable.end())
		{
			char buffer[10];
			sprintf_s(buffer, "UNKNOWN (0x%x)", status);
			return buffer;
		}
		return find->second;
	}

	int recv(SOCKET sock, void* buffer, int size, int flags)
	{
		int result = ::recv(sock, (char*)buffer, size, flags);
		if (result == 0)
		{
			//printf("Socket closed: %x\n", sock);
			return result;
		}

		if (result == SOCKET_ERROR)
		{
			//printf("Error recving from socket: %x\n", sock);
			return result;
		}

		if (result != size)
		{
			int new_result = recv(sock, (void*)((DWORD_PTR)buffer + result), size - result, flags);
			if (new_result <= 0) return new_result;

			return result + new_result;
		}

		return result;
	}

	void EncryptData(LPVOID data, SIZE_T size, DWORD key)
	{
		BYTE keyByte[4] = {
			BYTE(key & 0xFF),
			BYTE((key & 0xFF00) >> 8),
			BYTE((key & 0xFF0000) >> 16),
			BYTE((key & 0xFF000000) >> 24),
		};

		for (int i = 0; i < size; i += 4)
		{
			int sizeLeft = size - i;
			if (sizeLeft < 4)
			{
				for (int j = 0; j < sizeLeft; j++)
				{
					*(BYTE*)((BYTE*)data + i + j) = *(BYTE*)((BYTE*)data + i + j) ^ keyByte[j];
				}
			}
			else
			{
				*(DWORD*)((BYTE*)data + i) = *(DWORD*)((BYTE*)data + i) ^ key;
			}
		}
	}


	Packet::Packet(Client* owner, TCPSCOMMAND internalCmd, int cmd, int size, LPVOID copy)
	{
		this->owner = owner;
		header.cmd = cmd; // reserved

		header.internalCmd = internalCmd;
		header.size = size;

		if (size > 0)
		{
			body = std::shared_ptr<BYTE[]>(new BYTE[size]);
			memset(body.get(), 0, size);

			if (copy) memcpy(body.get(), copy, size);
		}
	}

	Packet::Packet(Client* owner, PACKET_HEADER header, LPVOID copy)
	{
		this->owner = owner;
		this->header = header;
		if (header.size > 0)
		{
			body = std::shared_ptr<BYTE[]>(new BYTE[header.size]);
			if (copy) memcpy(body.get(), copy, header.size);
		}
	}

	Packet::Packet(Client* owner)
	{
		this->owner = owner;
	}

	Packet::Packet(Client* owner, int cmd)
	{
		this->owner = owner;
		header.cmd = cmd;
	}

	Packet::Packet(Client* owner, int cmd, int size, LPVOID copy)
	{

		this->owner = owner;
		header.cmd = cmd;
		header.size = size;

		if (size > 0)
		{
			body = std::shared_ptr<BYTE[]>(new BYTE[size]);
			memset(body.get(), 0, size);

			if (copy) memcpy(body.get(), copy, size);
		}
	}

	Packet::Packet(Client* owner, int cmd, std::string string)
	{
		this->owner = owner;
		header.cmd = cmd;
		header.size = string.size() + 1;

		body = std::shared_ptr<BYTE[]>(new BYTE[header.size]);
		memset(body.get(), 0, header.size);

		if (header.size > 0) memcpy(body.get(), string.data(), header.size);
	}

	Packet::~Packet()
	{

	}

	bool Packet::send()
	{
		header.snowflake = owner->snowflake_send;

		int result = SOCKET_ERROR;
		int data_size = header.size;

		// ensure the packets are sent in order (avoid snowflake mismatched)
		std::unique_lock<std::mutex> sendLock(owner->mtxSend);

		int buffer_size = sizeof(header) + header.size;
		BYTE* buffer = new BYTE[buffer_size];
		memcpy_s(buffer, buffer_size, &header, sizeof(header));
		if (header.size > 0) memcpy_s(buffer + sizeof(header), buffer_size - sizeof(header), body.get(), header.size);

		// encrypt the packet
		EncryptData(buffer, buffer_size, header.snowflake);

		//WSABUF WSABuffer = { buffer_size, (CHAR*)buffer };
		//DWORD totalBytesSent = 0;
		//result = WSASend(owner->sock, (LPWSABUF)buffer, buffer_size, &totalBytesSent, 0, )
		result = ::send(owner->sock, (const char*)buffer, buffer_size, 0);
		
		delete[] buffer;

		// if failed to send
		if ((result == SOCKET_ERROR) || (result != buffer_size))
		{
			return false;
		}

		owner->snowflake_send = SNOWFLAKE_NEXT(owner->snowflake_send);
		return true;
	}

	bool Packet::request()
	{
		// cannot send a response packet
		assert(header.response_snowflake == 0);

		header.snowflake = owner->snowflake_send;

		bool bHasHandler = doneHandler != nullptr || failHandler != nullptr;
		if (bHasHandler)
		{
			// add the response handler to requestQueue

			RequestQueuePacket rsp;
			rsp.timeInit = clock();
			rsp.doneHandler = doneHandler;
			rsp.failHandler = failHandler;

			{
				std::unique_lock<std::mutex> queueLock(owner->mtxQueue);
				owner->requestQueue[header.snowflake] = rsp;
			}
		}

		if (send()) return true;

		if (bHasHandler)
		{
			// remove the queued request
			std::unique_lock<std::mutex> queueLock(owner->mtxQueue);
			owner->requestQueue.erase(header.snowflake);
			queueLock.unlock();

			if (failHandler) failHandler();
		}
		return false;
	}

	bool Packet::response(int cmd)
	{
		return response(cmd, 0, 0);
	}

	bool Packet::response(int cmd, std::string string)
	{
		return response(cmd, string.size() + 1, (LPVOID)string.data());
	}

	bool Packet::response(int cmd, int size, LPVOID copy)
	{
		assert(owner != nullptr);
		Packet pckt = owner->packet(cmd, size, copy);
		return response(pckt);
	}

	bool Packet::response(Packet& response)
	{
		response.header.response_snowflake = header.snowflake;
		return response.send();
	}
	Packet& Packet::done(PacketDoneHandler&& handler)
	{
		doneHandler = handler;
		return *this;
	}

	Packet& Packet::fail(PacketFailHandler&& handler)
	{
		failHandler = handler;
		return *this;
	}

	BYTE* Packet::data(size_t offset)
	{
		return body.get() + offset;
	}


	PACKET_HEADER Packet::GetHeader()
	{
		return header;
	}

	int Packet::cmd()
	{
		return header.cmd;
	}

	int Packet::size()
	{
		return header.size;
	}


	Client::Client(std::string IPAddress, int Port)
	{
		this->IPAddress = IPAddress;
		this->Port = Port;
	}

	Client::Client(SOCKET sock)
	{
		this->sock = sock;
	}

	Client::~Client()
	{
		disconnect();

		if (t_recv != nullptr && t_recv->joinable())
		{
			t_recv->join();
			delete t_recv;
		}
	}


	NWSTATUS Client::RecvPacket(Packet* packet)
	{
		PACKET_HEADER header;

		// get message size
		int bytes_recv = recv(sock, (char*)&header, sizeof(header), 0);
		if ((bytes_recv == SOCKET_ERROR) || (bytes_recv == 0 && WSAGetLastError() == 0))
		{
			return handleError(NWSTATUS::DISCONNECT, (LPVOID)bytes_recv);
		}
		else if (bytes_recv != sizeof(header))
		{
			return handleError(NWSTATUS::DATA_CORRUPT, (LPVOID)bytes_recv);
		}

		EncryptData(&header, sizeof(header), snowflake_recv);

		*packet = Packet(this, header);

		if (header.size > 0)
		{
			// get the actual message
			bytes_recv = recv(sock, packet->data(), header.size, 0);
			if ((bytes_recv == SOCKET_ERROR) || (bytes_recv == 0 && WSAGetLastError() == 0))
			{
				return handleError(NWSTATUS::DISCONNECT, (LPVOID)bytes_recv);
			}
			else if (bytes_recv != header.size)
			{
				return handleError(NWSTATUS::DATA_CORRUPT, (LPVOID)bytes_recv);
			}

			EncryptData(packet->data(), header.size, snowflake_recv);
		}

		// make sure the snowflakes match
		if (snowflake_recv != header.snowflake)
			return handleError(NWSTATUS::INVALID_SNOWFLAKE, (LPVOID)packet);

		snowflake_recv = SNOWFLAKE_NEXT(snowflake_recv);
		return NWSTATUS::OK;
	}

	NWSTATUS Client::ProcessPacket(Packet* packet)
	{
		lastHeartBeat = clock();

		if (packet->header.internalCmd == TCPSCOMMAND::USERDATA)
		{


			if (packet->header.response_snowflake != 0)
			{
				std::unique_lock<std::mutex> lck(mtxQueue);
				auto find = requestQueue.find(packet->header.response_snowflake);

				if (find != requestQueue.end())
				{
					lck.unlock();

					packet->owner = find->second.packet.owner;

					NWSTATUS status = NWSTATUS::OK;

					if (find->second.doneHandler != NULL)
					{
						//printf("%llp\n", find->second.doneHandler);
						find->second.doneHandler(*packet);
					}
					else
					{
						status = handleError(NWSTATUS::NO_HANDLER, (LPVOID)packet);
					}

					lck.lock();
					requestQueue.erase(find);
					lck.unlock();

					return status;
				}
				else
				{
					return handleError(NWSTATUS::NO_HANDLER, (LPVOID)packet);
				}
			}
			else
			{
				auto find = requestHandlers.find(packet->header.cmd);

				if (find != requestHandlers.end())
				{
					// call the handler
					find->second(this, *packet);
					return NWSTATUS::OK;
				}
				else
				{
					return handleError(NWSTATUS::NO_HANDLER, (LPVOID)packet);
				}
			}
		}
		else
		{
			// internalCmd must be TCPSCOMMAND::USERDATA when responding
			switch (packet->header.internalCmd)
			{
			case TCPSCOMMAND::HEARTBEAT:
				packet->response(int(TCPSCOMMAND::HEARTBEAT));
			}
		}
		return NWSTATUS::OK;
	}

	void Client::IntervalCheck()
	{

		clock_t now = clock();

		// heartbeat
		if ((now - lastHeartBeat) >= HEARTBEAT_INTERVAL)
		{
			lastHeartBeat = now;
			packet(TCPSCOMMAND::HEARTBEAT)
			.done([=](Packet result)
			{
				if (result.cmd() != int(TCPSCOMMAND::HEARTBEAT))
				{
					disconnect();
				}
			})
			.fail([=]
			{
				disconnect();
			}).request();
		}

		// check for timed out queued request
		{
			std::unique_lock<std::mutex> lck(mtxQueue);
			if (requestQueue.size() > 0)
			{
				std::vector<DWORD> eraseQueue;

				for (auto& it : requestQueue)
				{
					clock_t timePassed = now - it.second.timeInit;
					if (timePassed > REQUEST_TIMEOUT_MS)
					{
						if (it.second.failHandler) it.second.failHandler();
						else handleError(NWSTATUS::NO_FAIL_HANDLER, (LPVOID)&it.second.packet);

						eraseQueue.push_back(it.first);
					}
				}

				for (auto& it : eraseQueue)
				{
					requestQueue.erase(it);
				}

			}
		}
	}

	void Client::threadRecv()
	{
		isThreadAlive = true;

		WSAPOLLFD connection = { sock, POLLRDNORM, 0 };

		while (true)
		{
			int result = WSAPoll(&connection, 1, POLLER_REFRESH_INTERVAL);
			if (result < 0) break;

			if (result > 0)
			{
				auto revents = connection.revents;

				if (revents & POLLRDNORM)
				{
					Packet packet;
					NWSTATUS status = NWSTATUS::OK;

					status = RecvPacket(&packet);
					if (status != NWSTATUS::OK) break;

					ProcessPacket(&packet);
				}
				else if (revents & POLLERR || revents & POLLHUP)
				{
					break;
				}

			}

			IntervalCheck();

		}

		closesocket(sock);
		cleanup();


		if (onDisconnectHandler)
		{
			std::thread callback(onDisconnectHandler, this);
			callback.detach();
		}
		isThreadAlive = false;
	}

	NWSTATUS Client::handleError(NWSTATUS status, LPVOID data)
	{
		if (errorHandler) errorHandler(this, status, data);
		return status;
	}

	NWSTATUS Client::connect(int timeout)
	{
		snowflake_recv = TCPS_SNOWFLAKE;
		snowflake_send = TCPS_SNOWFLAKE;
		if (sock == INVALID_SOCKET)
		{
			sockaddr_in hint;
			hint.sin_family = AF_INET;
			hint.sin_port = htons(Port);
			inet_pton(AF_INET, IPAddress.c_str(), &hint.sin_addr);

			sock = ::socket(AF_INET, SOCK_STREAM, 0);

			//set the socket in non-blocking
			unsigned long iMode = 1;
			int iResult = ioctlsocket(sock, FIONBIO, &iMode);
			if (iResult != NO_ERROR)
			{
				sock = INVALID_SOCKET;
				return handleError(NWSTATUS::IOTCL_FAILED, (LPVOID)iResult);
			}

			if (::connect(sock, (struct sockaddr*)&hint, sizeof(hint)) == false)
			{
				closesocket(sock);
				sock = INVALID_SOCKET;
				return handleError(NWSTATUS::CONNECT_FAILED, (LPVOID)iResult);
			}

			// restart the socket mode
			iMode = 0;
			iResult = ioctlsocket(sock, FIONBIO, &iMode);
			if (iResult != NO_ERROR)
			{
				closesocket(sock);
				sock = INVALID_SOCKET;
				return handleError(NWSTATUS::IOTCL_FAILED, (LPVOID)iResult);
			}

			fd_set Write, Err;
			FD_ZERO(&Write);
			FD_ZERO(&Err);
			FD_SET(sock, &Write);
			FD_SET(sock, &Err);

			TIMEVAL Timeout;
			Timeout.tv_sec = timeout / 1000;
			Timeout.tv_usec = 0;
			// check if the socket is ready
			select(0, NULL, &Write, &Err, &Timeout);
			if (!FD_ISSET(sock, &Write))
			{
				closesocket(sock);
				sock = INVALID_SOCKET;
				return handleError(NWSTATUS::CONNECT_TIMEOUT, (LPVOID)iResult);
			}

		}

		if (!isThreadAlive)
		{
			t_recv = new std::thread(&Client::threadRecv, this);
			//t_recv.detach();
		}

		char bufferIP[24];
		sockaddr_in sockaddr;
		socklen_t len = sizeof(sockaddr);

		ZeroMemory(bufferIP, sizeof(bufferIP));
		ZeroMemory(&sockaddr, sizeof(sockaddr));

		return NWSTATUS::OK;
	}

	void Client::cleanup()
	{
		// close the socket, release all waiting connection
		std::unique_lock<std::mutex> queueLock(mtxQueue);
		for (auto& it : requestQueue)
		{
			if (it.second.failHandler)
			{
				it.second.failHandler();
			}
			else
			{
				Packet& packet = it.second.packet;
				handleError(NWSTATUS::NO_FAIL_HANDLER, &packet);
			}
		}
		requestQueue.clear();

		sock = INVALID_SOCKET;


	}

	void Client::disconnect()
	{
		closesocket(sock);

	}

	void Client::AddHandler(int cmd, RequestHandler* handler)
	{
		requestHandlers[cmd] = handler;
	}

	void Client::RemoveHandler(int cmd)
	{
		if (requestHandlers.find(cmd) != requestHandlers.end())
			requestHandlers.erase(cmd);
	}

	void Client::AddErrorHandler(ErrorHandler* handler)
	{
		errorHandler = handler;
	}

	void Client::onDisconnect(DisconnectHandler* handler)
	{
		onDisconnectHandler = handler;
	}

	Packet Client::packet(TCPSCOMMAND internalCmd, int cmd, int size, LPVOID copy)
	{
		return Packet(this, internalCmd, cmd, size, copy);
	}

	Packet Client::packet(int cmd)
	{
		return Packet(this, cmd);
	}

	Packet Client::packet(int cmd, std::string string)
	{
		return Packet(this, cmd, string);
	}

	Packet Client::packet(int cmd, int size, LPVOID copy)
	{
		return Packet(this, cmd, size, copy);
	}

	Packet Client::packet(int cmd, int size, const char* copy)
	{
		return Packet(this, cmd, size, (LPVOID)copy);
	}

	void ServerPoller::PollerThread()
	{
		clock_t interval = clock();

		while (true)
		{
			int result = WSAPoll(connections.data(), connections.size(), POLLER_REFRESH_INTERVAL);

			if (result != 0)
			{
				std::vector<SOCKET> removeQueue;

				for (int i = 0; i < connections.size(); i++)
				{
					auto revents = connections[i].revents;
					auto socket = connections[i].fd;
					auto client = clients[socket];

					if (revents & POLLRDNORM)
					{
						Packet packet;
						NWSTATUS status = NWSTATUS::OK;

						status = client->RecvPacket(&packet);
						if (status == NWSTATUS::OK)
						{
							client->ProcessPacket(&packet);
						}
						else
						{
							removeQueue.push_back(socket);
						}
						//count++;
					}
					else if (revents & POLLERR || revents & POLLHUP || revents & POLLNVAL)
					{
						removeQueue.push_back(socket);
					}
				}

				for (auto& it : removeQueue) RemoveConnection(it);
			}

			// add waiting connection to the list
			std::unique_lock<std::mutex> lck(mtxConnection);
			int waitingSize = waitingConnections.size();
			if (waitingSize > 0)
			{
				for (int i = 0; i < waitingSize; i++)
				{
					AddConnection(waitingConnections[i]);
				}
				waitingConnections.clear();
			}
			else if (connections.size() == 0)
			{
				// no more incomming connection, and all current connections are disconnected
				break;
			}

			// make clients check for request timeout every 1000ms
			clock_t now = clock();
			if ((now - interval) > 1000)
			{
				interval = now;
				for (auto& it : clients) it.second->IntervalCheck();
			}
		}
		owner->RemovePoller();
	}

	ServerPoller::ServerPoller(Server* owner, SOCKET firstSocket)
	{
		this->owner = owner;

		AddConnection(firstSocket);

		mainThread = std::thread(&ServerPoller::PollerThread, this);
		mainThread.detach();
	}

	void ServerPoller::AddConnection(SOCKET socket)
	{
		if (clients.find(socket) != clients.end())
		{
			//printf("Socket already exists %d", socket);
			//1;
			RemoveConnection(socket);
		}
		WSAPOLLFD fd = { socket, POLLRDNORM, 0 };
		connections.push_back(fd);


		char bufferIP[24];
		sockaddr_in sockaddr;
		socklen_t len = sizeof(sockaddr);

		ZeroMemory(bufferIP, sizeof(bufferIP));
		ZeroMemory(&sockaddr, sizeof(sockaddr));

		getpeername(socket, (struct sockaddr*)&sockaddr, &len);
		inet_ntop(AF_INET, &sockaddr.sin_addr, bufferIP, sizeof(bufferIP));

		std::shared_ptr<Client> client(new Client(socket));
		client->requestHandlers = owner->requestHandlers;
		client->AddErrorHandler(owner->errorHandler);
		client->snowflake_recv = TCPS_SNOWFLAKE;
		client->snowflake_send = TCPS_SNOWFLAKE;
		client->IPAddress = bufferIP;
		client->Port = sockaddr.sin_port;
		client->owner = owner;

		clients[socket] = client;


		if (owner->onAcceptHandler && !owner->onAcceptHandler(client.get()))
		{
			RemoveConnection(socket);
		}
	}

	void ServerPoller::RemoveConnection(SOCKET socket)
	{
		for (auto it = connections.begin(); it != connections.end(); it++)
		{
			if (it._Ptr->fd == socket)
			{
				if (owner->onDisconnectHandler)
				{
					owner->onDisconnectHandler(clients[socket].get());
				}
				clients[socket]->disconnect();
				clients[socket]->cleanup();
				clients.erase(socket);
				connections.erase(it);
				break;
			}
		}
	}

	Server::Server(int Port)
	{
		this->Port = Port;
	};

	Server::~Server()
	{

	}

	void Server::AddHandler(int cmd, RequestHandler* handler)
	{
		requestHandlers[cmd] = handler;
	}

	void Server::RemoveHandler(int cmd)
	{
		requestHandlers.erase(cmd);
	}

	void Server::AddErrorHandler(ErrorHandler* handler)
	{
		errorHandler = handler;
	}

	void Server::onDisconnect(DisconnectHandler* handler)
	{
		onDisconnectHandler = handler;
	}

	void Server::onAccept(AcceptHandler* handler)
	{
		onAcceptHandler = handler;
	}

	void Server::onPollerCreation(PollerEventHandler* handler)
	{
		onPollerCreationHandler = handler;
	}

	void Server::onPollerDestruction(PollerEventHandler* handler)
	{
		onPollerDestructionHandler = handler;
	}

	void Server::RemovePoller()
	{
		int index = 0;
		for (auto it = pollers.begin(); it != pollers.end(); it++, index++)
		{
			if (it._Ptr->get()->ConnectionsSize() == 0)
			{
				if (onPollerDestructionHandler)
					onPollerDestructionHandler(it._Ptr->get(), index);

				pollers.erase(it);
				break;
			}
		}
	}
	void Server::AddPoller(SOCKET sock)
	{
		std::shared_ptr<ServerPoller> poller(new ServerPoller(this, sock));
		pollers.push_back(poller);

		if (onPollerCreationHandler)
			onPollerCreationHandler(poller.get(), pollers.size() - 1);
	}


	void Server::threadAccept()
	{

		int buffsize = 1024 * 1024;
		setsockopt(listening, SOL_SOCKET, SO_RCVBUF, (char*)&buffsize, sizeof(buffsize));

		while (true)
		{

			sockaddr_in info;
			socklen_t leninfo = sizeof(info);
			SOCKET sock = WSAAccept(listening, (sockaddr*)&info, &leninfo, NULL, NULL);

			if (sock == INVALID_SOCKET)
			{
				// WARNING: Unhandle error
				// TODO: Add an error handler somehow
				continue;

				//printf("WSAGetLastError %x\n", WSAGetLastError());
				//assert(false);
			}


			setsockopt(sock, SOL_SOCKET, SO_RCVBUF, (char*)&buffsize, sizeof(buffsize));


			std::unique_lock<std::mutex> lck(mtxPollers);
			if (pollers.size() == 0)
			{
				AddPoller(sock);
			}
			else
			{
				auto poller = pollers.back();

				std::unique_lock<std::mutex> lckAdd(poller->mtxConnection);
				int current_size = poller->ConnectionsSize() + poller->waitingConnections.size();
				lck.unlock();

				if (current_size >= MAX_POLLER_CONNECTION)
				{
					AddPoller(sock);
				}
				else
				{
					lck.lock();
					poller->waitingConnections.push_back(sock);
					lck.unlock();
				}
			}
		}
	}

	NWSTATUS Server::start(bool newThread)
	{

		listening = socket(AF_INET, SOCK_STREAM, 0);
		if (listening == INVALID_SOCKET)
		{
			return NWSTATUS::SOCKET_FAILED;
		}

		sockaddr_in hint;
		hint.sin_family = AF_INET;
		hint.sin_port = htons(Port);
		hint.sin_addr.S_un.S_addr = INADDR_ANY;

		if (bind(listening, (sockaddr*)&hint, sizeof(hint)) == SOCKET_ERROR)
		{
			return NWSTATUS::BIND_FAILED;
		}

		if (listen(listening, SOMAXCONN) == SOCKET_ERROR)
		{
			return NWSTATUS::LISTEN_FAILED;
		}

		if (newThread)
		{
			t_accept = std::thread(&Server::threadAccept, this);
			t_accept.detach();
			return NWSTATUS::OK;
		}

		threadAccept();
		return NWSTATUS::OK;
	}
}