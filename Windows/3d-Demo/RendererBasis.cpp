#include "RendererBasis.h"

DeviceBuilder::DeviceBuilder() {
	HRESULT hr = S_OK;

	const D3D_FEATURE_LEVEL* levels = VERSION_LEVELS.data();
	UINT levelCount = static_cast<UINT>(VERSION_LEVELS.size());

	UINT flags = D3D11_CREATE_DEVICE_BGRA_SUPPORT;

#if defined(_DEBUG) || defined(DEBUG) 
	flags |= D3D11_CREATE_DEVICE_DEBUG;
#endif

	hr = D3D11CreateDevice(
		nullptr,
		D3D_DRIVER_TYPE_HARDWARE,
		nullptr,
		flags,
		levels,
		levelCount,
		D3D11_SDK_VERSION,
		&this->device,
		&this->featureLevel,
		&this->deviceContext
	);

	if (FAILED(hr)) {
		this->device.Reset();
		this->deviceContext.Reset();
	}
}

const ID3D11Device& DeviceBuilder::getDevice() const {
	return *this->device.Get();
}
const ID3D11DeviceContext& DeviceBuilder::getContext() const {
	return *this->deviceContext.Get();
}
D3D_FEATURE_LEVEL DeviceBuilder::getFeatureLevel() const {
	return this->featureLevel;
}