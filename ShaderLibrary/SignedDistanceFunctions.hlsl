#ifndef SIGNED_DISTANCE_FUNCTIONS
#define SIGNED_DISTANCE_FUNCTIONS

// Primitives are centered at the origin.
// Transform the position to translate, rotate and scale objects.
// Reference: https://iquilezles.org/www/articles/distfunctions/distfunctions.htm

// n: Normal to the plane (normalized).
float sdPlane( float3 p, float4 n )
{
	return dot(p, n.xyz) + n.w;
}

// l: Length.
float sdBox( float3 p, float3 l )
{
	float3 d = abs(p) - l;
	return length(max(d, 0.0))
		+ min(max(d.x, max(d.y, d.z)), 0.0); // Remove this line for an only partially signed sdf.
}

// r: Radius.
float sdSphere( float3 p, float r )
{
	return length(p) - r;
}

// r: Radius.
float sdEllipsoid( float3 p, float3 r )
{
	float k0 = length(p / r);
	float k1 = length(p / (r * r));
	return k0 * (k0 - 1.0) / k1;
}

// h: Height.
// r: Radius.
float sdCylinder( float3 p, float h, float r )
{
	float2 d = abs(float2(length(p.xz), p.y)) - float2(r, h);
	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

// h: Height.
// r: Radius.
float sdCapsule( float3 p, float h, float r )
{
	p.y -= clamp(p.y, -h / 2.0, h / 2.0);
	return length(p) - r;
}

// d: Diameter.
// t: Thickness.
float sdTorus( float3 p, float d, float t )
{
	float2 q = float2(length(p.xz) - d, p.y);
	return length(q) - t;
}

// h: Height.
// w: Width.
float sdTriangularPrism( float3 p, float h, float w )
{
	float3 q = abs(p);
	return max(q.z - w, max(q.x * 0.866025 + p.y * 0.5, -p.y) - h * 0.5);
}

// h: Height.
// w: Width.
float sdHexagonalPrism( float3 p, float h, float w )
{
	const float3 k = float3(-0.8660254, 0.5, 0.57735);
	p = abs(p);
	p.xy -= 2.0 * min(dot(k.xy, p.xy), 0.0) * k.xy;
	float2 d = float2(
		length(p.xy - float2(clamp(p.x, -k.z * h, k.z * h), h)) * sign(p.y - h),
		p.z - w);

	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

#endif