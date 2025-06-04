#pragma once

#include "Core.h"
#include <DirectXMath.h>

struct Vertex {
public:
	Vertex(DirectX::XMFLOAT3 pos, DirectX::XMFLOAT3 color) : position(pos), color(color) { }

	DirectX::XMFLOAT3 position;
	DirectX::XMFLOAT3 color;
};

class MeshBase {
protected:
	com_ptr<ID3D11Buffer> buffer;
	unsigned vertexCount;

public:
	virtual ~MeshBase() = default;

	const ID3D11Buffer& getBuffer() const {
		return &this->buffer;
	}
	unsigned getCount() const {
		return this->vertexCount;
	}
};

class IndexBasedMesh : public MeshBase {
protected:
	com_ptr<ID3D11Buffer> indexBuffer;
	unsigned indexCount;

public:
	const ID3D11Buffer& getIndexBuffer() const {
		return &this->indexBuffer;
	}
	unsigned getIndexCount() const {
		return this->indexCount;
	}
};