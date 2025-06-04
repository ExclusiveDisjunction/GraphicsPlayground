#pragma once

#include <iostream>
#include <vector>
#include <string>
#include <memory>
#include <d3d11.h>
#include <d3d11_3.h>
#include <wrl\client.h>
#pragma comment(lib, "d3d11.lib")

template<typename T>
using com_ptr = Microsoft::WRL::ComPtr<T>;

class HResultError : std::logic_error {
public:
	HResultError(HRESULT hr) : std::logic_error("a HRESULT of value " + std::to_string(hr) + " is a failure") {
		this->hr = hr;
	}

	HRESULT hr;
};

extern const std::vector<D3D_FEATURE_LEVEL> VERSION_LEVELS;