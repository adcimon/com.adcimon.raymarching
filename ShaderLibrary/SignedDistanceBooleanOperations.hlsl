#ifndef SIGNED_DISTANCE_BOOLEAN_OPERATIONS
#define SIGNED_DISTANCE_BOOLEAN_OPERATIONS

// References:
// https://iquilezles.org/www/articles/distfunctions/distfunctions.htm
// https://iquilezles.org/www/articles/smin/smin.htm

// Smooth min polynomial.
// Not commutative, order dependent.
// Suffers from second order discontinuities.
// k: Controls the radius/distance of the smoothness (k = 0.1).
float smin_pol( float a, float b, float k )
{
	float h = clamp(0.5 + 0.5 * (b - a) / k, 0, 1);
	return lerp(b, a, h) - k * h * (1 - h);
}

float smin_pol_color( float a, float b, float k, float4 c1, float4 c2, out float4 c )
{
	float h = clamp(0.5 + 0.5 * (b - a) / k, 0, 1);
	c = lerp(c2, c1, h);
	return lerp(b, a, h) - k * h * (1 - h);
}

// Smooth min polynomial cubic.
// Not commutative, order dependent.
// Has second order continuity, important for preventing lighting artifacts.
// k: Controls the radius/distance of the smoothness (k = 0.1).
float smin_cubic( float a, float b, float k )
{
	float h = max(k - abs(a - b), 0) / k;
	return min(a, b) - h * h * h * k * (1.0 / 6.0);
}

// Smooth min power.
// Generalize to more than two distances.
// k: Controls the radius/distance of the smoothness (k = 8).
float smin_pow( float a, float b, float k )
{
	a = pow(a, k); b = pow(b, k);
	return pow((a*b) / (a + b), 1.0 / k);
}

// Smooth min exponencial.
// Generalize to more than two distances.
// Commutative when taken in pairs, smin(a, smin(b, c)) is equal to smin(b, smin(a, c)).
// k: Controls the radius/distance of the smoothness (k = 32).
float smin_exp( float a, float b, float k )
{
	float res = exp2(-k * a) + exp2(-k * b);
	return -log2(res) / k;
}

// Smooth max polynomial.
// Not commutative, order dependent.
// Suffers from second order discontinuities.
// k: Controls the radius/distance of the smoothness (k = 32).
float smax_pol( float a, float b, float k )
{
	float h = clamp(0.5 - 0.5 * (b - a) / k, 0, 1);
	return lerp(b, a, h) + k * h * (1 - h);
}

float smax_pol_color( float a, float b, float k, float4 c1, float4 c2, out float4 c )
{
	float h = clamp(0.5 - 0.5 * (b - a) / k, 0, 1);
	c = lerp(c2, c1, h);
	return lerp(b, a, h) + k * h * (1 - h);
}

// Union boolean operation.
float opUnion( float d1, float d2 )
{
	return min(d1, d2);
}

// Intersection boolean operation.
float opIntersection( float d1, float d2 )
{
	return max(d1, d2);
}

// Subtraction boolean operation.
// Not commutative and depending on the order of the operands it will produce different results.
float opSubtraction( float d1, float d2 )
{
	return max(-d1, d2);
}

// Union boolean operation.
// k: Controls the radius/distance of the smoothness (k = 0.1).
float opSmoothUnion( float d1, float d2, float k )
{
	return smin_pol(d1, d2, k);
}

float opSmoothUnionColor( float d1, float d2, float k, float4 c1, float4 c2, out float4 c )
{
	return smin_pol_color(d1, d2, k, c1, c2, c);
}

// Intersection boolean operation.
// k: Controls the radius/distance of the smoothness (k = 0.1).
float opSmoothIntersection( float d1, float d2, float k )
{
	return smax_pol(d1, d2, k);
}

float opSmoothIntersectionColor( float d1, float d2, float k, float4 c1, float4 c2, out float4 c )
{
	return smax_pol_color(d1, d2, k, c1, c2, c);
}

// Subtraction boolean operation.
// Not commutative and depending on the order of the operands it will produce different results.
// k: Controls the radius/distance of the smoothness (k = 0.1).
float opSmoothSubtraction( float d1, float d2, float k )
{
	return smax_pol(-d1, d2, k);
}

float opSmoothSubtractionColor( float d1, float d2, float k, float4 c1, float4 c2, out float4 c )
{
	return smax_pol_color(-d1, d2, k, c1, c2, c);
}

#endif