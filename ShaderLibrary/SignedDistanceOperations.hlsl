#ifndef SIGNED_DISTANCE_OPERATIONS
#define SIGNED_DISTANCE_OPERATIONS

// References:
// https://iquilezles.org/www/articles/distfunctions/distfunctions.htm
// http://mercury.sexy/hg_sdf/

// GLSL mod(x, y) -> x - y * floor(x / y)
// HLSL fmod(x, y) -> x - y * trunc(x / y)
// In GLSL the output sign depends on the sign of y, in HLSL the sign depends on x.
float mod( float x, float y )
{
	return x - y * floor(x / y);
}

// Round a shape.
// Subtracts some distance (jumping to a different isosurface).
// If you want to preserve the overal volume of the shape, shrink the source primitive by the same amount you are rounding it.
// r: Radius.
float opRound( float d, float r )
{
	return d - r;
}

// Carve the interior or give thickness to primitive.
// Use it multiple times to create concentric layers.
// t: Thickness.
float opOnion( float d, float t )
{
	return abs(d) - t;
}

// Twist the point across the x axis.
// k: Twist factor.
float3 opTwistX( float3 p, float k )
{
	float c = cos(k * p.x);
	float s = sin(k * p.x);
	float3x3 m = float3x3(1, 0, 0, 0, c, -s, 0, s, c);
	float3 q = mul(m, p);
	return q;
}

// Twist the point across the y axis.
// k: Twist factor.
float3 opTwistY( float3 p, float k )
{
	float c = cos(k * p.y);
	float s = sin(k * p.y);
	float3x3 m = float3x3(c, 0, s, 0, 1, 0, -s, 0, c);
	float3 q = mul(m, p);
	return q;
}

// Twist the point across the z axis.
// k: Twist factor.
float3 opTwistZ( float3 p, float k )
{
	float c = cos(k * p.z);
	float s = sin(k * p.z);
	float3x3 m = float3x3(c, -s, 0, s, c, 0, 0, 0, 1);
	float3 q = mul(m, p);
	return q;
}

// Repeat space along one axis and returns the cell (optional).
// float c = pMod1(p.x, 1);
// c: Cell.
float opMod1( inout float p, float size )
{
	float halfsize = size * 0.5;
	float c = floor((p + halfsize) / size);
	p = fmod(p + halfsize, size) - halfsize;
	p = fmod(-p + halfsize, size) - halfsize;
	return c;
}

// Repeat space along one positive axis and returns the cell (optional).
// float c = pModPositive1(p.x, 1);
// c: Cell.
float opModPositive1( inout float p, float size )
{
	float halfsize = size * 0.5;
	float c = floor((p + halfsize) / size);
	if( p >= 0 )
	{
		p = mod(p + halfsize, size) - halfsize;
	}

	return c;
}

// Repeat space along one axis from start to end cells and returns the cell (optional).
// float c = pModInterval1(p.x, 1, 0, 10);
// c: Cell.
float opModInterval1( inout float p, float size, int start, int end )
{
	float halfsize = size * 0.5;
	float c = floor((p + halfsize) / size);
	p = mod(p + halfsize, size) - halfsize;
	if( c > end )
	{
		p += size * (c - end);
		c = end;
	}
	if( c < start )
	{
		p += size * (c - start);
		c = start;
	}

	return c;
}

// Repeat space along two axes and returns the cell (optional).
// float2 c = pMod2(p.x, p.y, 1);
// c: Cell.
float2 opMod2( inout float p1, inout float p2, float2 size )
{
	float2 c = floor((float2(p1, p2) + size * 0.5) / size);
	p1 = mod(p1 + size.x * 0.5, size.x) - size.x * 0.5;
	p2 = mod(p2 + size.y * 0.5, size.y) - size.y * 0.5;
	return c;
}

// Repeat space along three axes and returns the cell (optional).
// float3 c = pMod3(p.x, p.y, p.z, 1);
// c: Cell.
float3 opMod3( inout float p1, inout float p2, inout float p3, float3 size )
{
	float3 c = floor((float3(p1, p2, p3) + size * 0.5) / size);
	p1 = mod(p1 + size.x * 0.5, size.x) - size.x * 0.5;
	p2 = mod(p2 + size.y * 0.5, size.y) - size.y * 0.5;
	p3 = mod(p3 + size.z * 0.5, size.z) - size.z * 0.5;
	return c;
}

#endif