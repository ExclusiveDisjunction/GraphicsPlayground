#include "Transform.h"

StandardTransformations::StandardTransformations(Float3 pos, Float3 rot, Float3 scale) : pos(pos), rot(rot), scale(scale) {}

DirectX::XMFLOAT4X4 StandardTransformations::getModelMatrix() const {
	DirectX::XMMATRIX trans = DirectX::XMMatrixTranslation(pos.x, pos.y, pos.z);
	DirectX::XMMATRIX rot = DirectX::XMMatrixRotationZ(this->rot.z) * DirectX::XMMatrixRotationY(this->rot.y) * DirectX::XMMatrixRotationX(this->rot.x);
	DirectX::XMMATRIX scale = DirectX::XMMatrixScaling(this->scale.x, this->scale.y, this->scale.z);

	DirectX::XMMATRIX compute = scale * rot * trans;

	DirectX::XMFLOAT4X4 result;
	DirectX::XMStoreFloat4x4(&result, DirectX::XMMatrixTranspose(compute));
	return result;
}