#pragma once

#include "Core.h"
#include <Windows.h>
#include <d3d11.h>

class DeviceBuilder {
private:
	com_ptr<ID3D11Device> device;
	com_ptr<ID3D11DeviceContext> deviceContext;

	D3D_FEATURE_LEVEL featureLevel;
public:
	DeviceBuilder();

	const ID3D11Device& getDevice() const;
	const ID3D11DeviceContext& getContext() const;
	D3D_FEATURE_LEVEL getFeatureLevel() const;
};

class SwapChainManager {
private:
	com_ptr<IDXGISwapChain> swapChain;
	
};

class RendererBasis {

};