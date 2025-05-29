#include <Windows.h>

LRESULT __stdcall WndProc(HWND, UINT, WPARAM, LPARAM);

int __stdcall wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPWSTR cmdArgs, int nCommandArgs) {

	WNDCLASS wn = { 0 };
	wn.lpfnWndProc = WndProc;
	wn.hInstance = hInstance;
	wn.hCursor = LoadCursor(NULL, IDC_ARROW);
	wn.hbrBackground = NULL;
	wn.lpszMenuName = NULL;
	wn.lpszClassName = TEXT("Main Window");
	wn.hIcon = LoadIcon(NULL, IDI_APPLICATION);
	wn.cbWndExtra = 0;
	wn.style = CS_HREDRAW | CS_VREDRAW;

	ATOM atom = RegisterClass(&wn);
	if (!atom)
		return 1;

	HWND window = CreateWindowEx(0l, MAKEINTATOM(atom), NULL, WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, NULL, NULL, hInstance, NULL);
	if (!window)
		return 1;

	ShowWindow(window, SW_NORMAL);
	UpdateWindow(window);

	MSG msg;
	while (GetMessage(&msg, NULL, 0, 0) != 0) {
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	}

	return static_cast<int>(msg.wParam);
}

LRESULT __stdcall WndProc(HWND window, UINT msg, WPARAM wp, LPARAM lp) {
	switch (msg) {
	case WM_CREATE: 
		return 0;
	case WM_PAINT: {
		PAINTSTRUCT ps;
		HDC dc = BeginPaint(window, &ps);
		
		RECT rect;
		GetClientRect(window, &rect);

		HBRUSH bk = GetSysColorBrush(BLACK_BRUSH);
		FillRect(dc, &rect, bk);

		EndPaint(window, &ps);
		return 0;
	}
	case WM_DESTROY:
		PostQuitMessage(0);
		return 0;
	default:
		return DefWindowProc(window, msg, wp, lp);
	}
}