#pragma once

#include "Core.h"
#include <DirectXMath.h>

using Float3 = DirectX::XMFLOAT3;

class StandardTransformations {
public:
	StandardTransformations(Float3 pos = Float3(0, 0, 0), Float3 rot = Float3(0, 0, 0), Float3 scale = Float3(1, 1, 1));

	Float3 pos;
	Float3 rot;
	Float3 scale;
	
	/// <summary>
	///  Creates the model matrix for the specific transformations.
	/// </summary>
	/// <returns>A matrix encoding the translations. This will be stored in Column Major Order.</returns>
	DirectX::XMFLOAT4X4 getModelMatrix() const;
};