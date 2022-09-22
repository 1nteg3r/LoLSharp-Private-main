#pragma once


#pragma region Drawing
float s_left = 0.f;
float s_top = 0.f;
float s_width = 1920.f;
float s_height = 1080.f;
static LPDIRECT3D9 d3d;
static LPDIRECT3DDEVICE9 d3ddev;

ID3DXEffect* g_pEffect = NULL;
DWORD dwShaderFlags = 0;

LPDIRECT3DVERTEXBUFFER9 g_list_vb = NULL;
void *vb_vertices;

#define PI 3.14159265

D3DPRESENT_PARAMETERS d3dpp;    // create a struct to hold various device information
LPD3DXSPRITE pSpriteInterface;
//-----------------------------------------------------------------------------------
//CreateD3DTLVERTEX--Populate a D3DTLVERTEX structure
//-----------------------------------------------------------------------------------

bool initD3D(HWND hWnd)
{
	d3d = Direct3DCreate9(D3D_SDK_VERSION);    // create the Direct3D interface


	ZeroMemory(&d3dpp, sizeof(d3dpp));    // clear out the struct for use
	d3dpp.Windowed = TRUE;    // program windowed, not fullscreen
	d3dpp.SwapEffect = D3DSWAPEFFECT_DISCARD;    // discard old frames
	d3dpp.hDeviceWindow = hWnd;    // set the window to be used by Direct3D
	d3dpp.MultiSampleQuality = DEFAULT_QUALITY;
	//d3dpp.FullScreen_RefreshRateInHz = 0;
	d3dpp.BackBufferCount = 1; //set it to only use 1 backbuffer
	d3dpp.BackBufferFormat = D3DFMT_A8R8G8B8;     // set the back buffer format to 32-bit
	d3dpp.BackBufferWidth = s_width;    // set the width of the buffer
	d3dpp.BackBufferHeight = s_height;    // set the height of the buffer
	//d3dpp.PresentationInterval = D3DPRESENT_INTERVAL_ONE; // Present with vsync
	d3dpp.PresentationInterval = D3DPRESENT_INTERVAL_IMMEDIATE; // Present without vsync, maximum unthrottled framerate

	d3dpp.EnableAutoDepthStencil = FALSE;
	d3dpp.AutoDepthStencilFormat = D3DFMT_D16;

	// create a device class using this information and the info from the d3dpp stuct
	if (d3d->CreateDevice(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, hWnd, D3DCREATE_SOFTWARE_VERTEXPROCESSING, &d3dpp, &d3ddev) < 0)
		return false;

	return true;
}

void D3DX_Create_Texture(LPDIRECT3DDEVICE9 Device_Interface,
	PCHAR File_Path,
	LPDIRECT3DTEXTURE9 Texture_Interface)
{
	if (Device_Interface && File_Path && !Texture_Interface)
		D3DXCreateTextureFromFileA(Device_Interface, File_Path, &Texture_Interface);
}

void D3DX_Sprite(LPDIRECT3DDEVICE9 Device_Interface,
	LPDIRECT3DTEXTURE9 Texture_Interface,
	D3DXVECTOR3 Position)
{
	if (Device_Interface && !pSpriteInterface)
		D3DXCreateSprite(Device_Interface, &pSpriteInterface);
	if (pSpriteInterface && Texture_Interface && Position)
	{
		pSpriteInterface->Begin(D3DXSPRITE_ALPHABLEND);
		pSpriteInterface->Draw(Texture_Interface, NULL, NULL, &Position, 0xFFFFFFFF);

		pSpriteInterface->End();
	}
}

LPDIRECT3DTEXTURE9 pUltimateDot;


LPDIRECT3DTEXTURE9 pControlWard;
LPDIRECT3DTEXTURE9 pStealthWard;
LPDIRECT3DTEXTURE9 pTotemWard;
LPDIRECT3DTEXTURE9 pFarsightWard;

#pragma endregion Drawing