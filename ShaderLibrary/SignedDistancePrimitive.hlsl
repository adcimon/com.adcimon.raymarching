#ifndef SIGNED_DISTANCE_PRIMITIVE
#define SIGNED_DISTANCE_PRIMITIVE

struct SignedDistancePrimitive
{
	int type;
	float4x4 transform;
	float scale;
	float parameter0;
	float parameter1;
	float parameter2;
	float4 color;
	float shininess;
	float4 specularColor;
};

#endif