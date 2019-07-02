#ifndef RAYMARCHING_CORE
#define RAYMARCHING_CORE

#include "UnityCG.cginc"
#include "Lighting.cginc"

#include "SignedDistanceFunctions.hlsl"
#include "SignedDistanceBooleanOperations.hlsl"
#include "SignedDistanceOperations.hlsl"
#include "SignedDistancePrimitive.hlsl"

// Settings.
int _Steps = 64;
float _MinDistance = 0.01;
float _MaxDistance = 1000;
float _NormalOffset = 0.01;

// Camera.
float4 _CameraPositionWS;
float4x4 _CameraViewToWorld;
float4x4 _CameraFrustum;
sampler2D _CameraDepthTexture;
sampler2D _SourceTexture;

// Lighting.
float4 _AmbientColor = float4(0.212, 0.227, 0.259, 1);

// Shadows.
float2 _ShadowDistance = float2(0.1, 100);
float _ShadowIntensity = 1;
float _ShadowPenumbra = 1;

// Ambient Occlusion.
float _AmbientOcclusionStepSize = 0.1;
int _AmbientOcclusionIterations = 1;
float _AmbientOcclusionIntensity = 0;

// Primitives.
int _PrimitivesBufferSize;
StructuredBuffer<SignedDistancePrimitive> _PrimitivesBuffer;

struct Attributes
{
	float4 positionOS : POSITION;
	float2 uv : TEXCOORD0;
};

struct Varyings
{
	float4 positionCS : SV_POSITION;
	float2 uv : TEXCOORD0;
	float3 ray : TEXCOORD1;
};

struct RaymarchData
{
	float distance;
	float4 color;
	float shininess;
	float4 specularColor;
};

// Implement this function to create the signed distance field.
RaymarchData SignedDistanceField( float3 position );

float SignedDistanceFunction( SignedDistancePrimitive primitive, float3 position )
{
	// Scaling an object compresses/dilates spaces.
	position /= primitive.scale;

	switch( primitive.type )
	{
		case 0:		return sdPlane(position, float4(0, 1, 0, 0)) * primitive.scale;
		case 1:		return sdBox(position, float3(primitive.parameter0, primitive.parameter1, primitive.parameter2)) * primitive.scale;
		case 2:		return sdSphere(position, primitive.parameter0) * primitive.scale;
		case 3:		return sdEllipsoid(position, float3(primitive.parameter0, primitive.parameter1, primitive.parameter2)) * primitive.scale;
		case 4:		return sdCylinder(position, primitive.parameter0, primitive.parameter1) * primitive.scale;
		case 5:		return sdCapsule(position, primitive.parameter0, primitive.parameter1) * primitive.scale;
		case 6:		return sdTorus(position, primitive.parameter0, primitive.parameter1) * primitive.scale;
		case 7:		return sdTriangularPrism(position, primitive.parameter0, primitive.parameter1) * primitive.scale;
		case 8:		return sdHexagonalPrism(position, primitive.parameter0, primitive.parameter1) * primitive.scale;
		default:	return 0;
	}
}

// The technique used to calculate the normal samples the signed distance field at nearby points to get an estimation of the local surface curvature (essentially calculating the gradient at the position).
// The points sampled are located at: (position.x + offset), (position.x - offset), (position.y + offset), (position.y - offset), (position.z + offset) and (position.z - offset).
// Reference: http://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
float3 CalculateNormalCentralDifferences( float3 position, float offset )
{
	float3 N = normalize(float3(
		SignedDistanceField(position + float3(offset, 0, 0)).distance - SignedDistanceField(position - float3(offset, 0, 0)).distance,
		SignedDistanceField(position + float3(0, offset, 0)).distance - SignedDistanceField(position - float3(0, offset, 0)).distance,
		SignedDistanceField(position + float3(0, 0, offset)).distance - SignedDistanceField(position - float3(0, 0, offset)).distance
	));

	return N;
}

// The technique used to calculate the normal samples the signed distance field at nearby points to get an estimation of the local surface curvature (essentially calculating the gradient at the position).
// The points sampled are located at: (position.x + offset), (position.y + offset) and (position.z + offset).
// Reference: http://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
float3 CalculateNormalForwardDifferences( float3 position, float offset )
{
	float d = SignedDistanceField(position).distance;
	float3 N = normalize(float3(
		SignedDistanceField(position + float3(offset, 0, 0)).distance - d,
		SignedDistanceField(position + float3(0, offset, 0)).distance - d,
		SignedDistanceField(position + float3(0, 0, offset)).distance - d
	));

	return N;
}

// The technique used to calculate the normal samples the signed distance field at nearby points to get an estimation of the local surface curvature (essentially calculating the gradient at the position).
// The points sampled are located at the vertices of a tetrahedron.
// Reference: Work by Paul Malin in Shadertoy, based also on central differences (http://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm).
float3 CalculateNormalTetrahedron( float3 position, float offset )
{
	const float2 k = float2(1, -1);
	float3 N = normalize(float3(
		k.xyy * SignedDistanceField(position + k.xyy * offset).distance +
		k.yyx * SignedDistanceField(position + k.yyx * offset).distance +
		k.yxy * SignedDistanceField(position + k.yxy * offset).distance +
		k.xxx * SignedDistanceField(position + k.xxx * offset).distance
	));

	return N;
}

// Reference: https://www.iquilezles.org/www/articles/rmshadows/rmshadows.htm
float HardShadows( float3 origin, float3 direction )
{
	for( float t = _ShadowDistance.x; t < _ShadowDistance.y; )
	{
		float h = SignedDistanceField(origin + direction * t).distance;
		if( h < 0.001 )
		{
			return 0;
		}

		t += h;
	}

	return 1;
}

// Reference: https://www.iquilezles.org/www/articles/rmshadows/rmshadows.htm
float SoftShadows( float3 origin, float3 direction )
{
	float result = 1;
	for( float t = _ShadowDistance.x; t < _ShadowDistance.y; )
	{
		float h = SignedDistanceField(origin + direction * t).distance;
		if( h < 0.001 )
		{
			return 0;
		}

		result = min(result, _ShadowPenumbra * h / t);
		t += h;
	}

	return result;
}

// Reference: Sebastian Aaltonen.
float SoftShadowsImproved( float3 origin, float3 direction )
{
	float result = 1;
	float ph = 1e20;
	for( float t = _ShadowDistance.x; t < _ShadowDistance.y; )
	{
		float h = SignedDistanceField(origin + direction * t).distance;
		if( h < 0.001 )
		{
			return 0;
		}

		float y = h * h / (2 * ph);
		float d = sqrt(h * h - y * y);
		result = min(result, _ShadowPenumbra * d / max(0, t - y));
		ph = h;
		t += h;
	}

	return result;
}

// Reference: https://www.iquilezles.org/www/articles/rmshadows/rmshadows.htm
float AmbientOcclusion( float3 position, float3 normal )
{
	float ao = 0;

	for( int i = 1; i < _AmbientOcclusionIterations; i++ )
	{
		float d = _AmbientOcclusionStepSize * i;
		ao += max(0, (d - SignedDistanceField(position + normal * d).distance) / d);
	}

	return 1 - ao * _AmbientOcclusionIntensity;
}

// Shades the pixel using a Lambert or Blinn-Phong model with optional hard or soft shadows and ambient occlusion.
fixed4 Shade( float3 position, float3 normal, RaymarchData data )
{
	fixed3 color = data.color;
	fixed3 light = fixed3(0, 0, 0);

	float3 N = normal;
	fixed3 L = _WorldSpaceLightPos0.xyz;
	fixed NdotL = max(dot(N, L), 0);

	// Ambient.
	#if defined(AMBIENT)
	{
		fixed3 ambient = _AmbientColor.rgb; // unity_AmbientSky.rgb
		light += ambient;
	}
	#endif

	// Diffuse.
	fixed3 lightColor = _LightColor0.rgb;
	float3 diffuse = lightColor * NdotL;
	light += diffuse;

	// Specular.
	#if defined(SPECULAR)
	{
		float3 V = normalize(_WorldSpaceCameraPos - position.xyz);
		float3 R = normalize(reflect(-L, N));
		float RdotV = max(0, dot(R, V));
		fixed3 specular = pow(RdotV, data.shininess) * lightColor * ceil(NdotL) * data.specularColor.rgb;
		light += specular;
	}
	#endif

	// Lighting.
	color *= light;

	// Shadows.
	#if defined(HARD_SHADOWS)
	{
		float shadow = HardShadows(position, L) * 0.5 + 0.5;
		shadow = max(0, pow(shadow, _ShadowIntensity));
		color *= shadow;
	}
	#elif defined(SOFT_SHADOWS)
	{
		float shadow = SoftShadows(position, L) * 0.5 + 0.5;
		shadow = max(0, pow(shadow, _ShadowIntensity));
		color *= shadow;
	}
	#elif defined(SOFT_SHADOWS_IMPROVED)
	{
		float shadow = SoftShadowsImproved(position, L) * 0.5 + 0.5;
		shadow = max(0, pow(shadow, _ShadowIntensity));
		color *= shadow;
	}
	#endif

	// Ambient Occlusion.
	#if defined(AMBIENT_OCCLUSION)
	{
		float ambientOcclusion = AmbientOcclusion(position, N);
		color *= ambientOcclusion;
	}
	#endif

	return fixed4(color, 1);
}

// Distance-aided raymarching.
// Reference: https://iquilezles.org/www/articles/raymarchingdf/raymarchingdf.htm
fixed4 Raymarch( float3 origin, float3 direction, float2 uv, float depth )
{
	float t = 0;
	int i = 0;
	for( i = 0; i < _Steps; i++ )
	{
		if( t > depth ) // There is an object rendered before hiting the signed distance field.
		{
			break;
		}

		if( t > _MaxDistance ) // Reached the maximun distance to march over the ray without hiting the signed distance field.
		{
			break;
		}

		float3 p = origin + direction * t;
		RaymarchData data = SignedDistanceField(p);
		if( data.distance < _MinDistance ) // The ray hit the signed distance field.
		{
			#if defined(DEBUG_STEPS)
			{
				// Do not shade the pixel.
				break;
			}
			#else
			{
				// Shade the pixel.

				// Normal calculation.
				float3 N = float3(0, 0, 0);
				#if defined(NORMALS_FORWARD_DIFFERENCES)
				{
					N = CalculateNormalForwardDifferences(p, _NormalOffset);
				}
				#elif defined(NORMALS_TETRAHEDRON)
				{
					N = CalculateNormalTetrahedron(p, _NormalOffset);
				}
				#else
				{
					N = CalculateNormalCentralDifferences(p, _NormalOffset);
				}
				#endif

				return Shade(p, N, data);
			}
			#endif
		}

		t += data.distance;
	}

	#if defined(DEBUG_STEPS)
	{
		float steps = (float)i / _Steps;
		return fixed4(steps, 0, 0, 1);
	}
	#else
	{
		// The raymarch loop ended without hiting the signed distance field.
		// Return the source texture.
		return tex2D(_SourceTexture, uv.xy);
	}
	#endif
}

// Vertex shader.
Varyings Vertex( Attributes input )
{
	Varyings output;

	half index = input.positionOS.z; // Get the index of the camera frustum vector.
	input.positionOS.z = 0; // Set the z value to 0.

	output.positionCS = UnityObjectToClipPos(input.positionOS);
	output.uv = input.uv;

	output.ray = _CameraFrustum[(int)index].xyz;
	output.ray /= abs(output.ray.z); // Normalize the ray in the z direction.
	output.ray = mul(_CameraViewToWorld, output.ray); // Transform the ray from view space to world space.

	return output;
}

// Fragment shader.
fixed4 Fragment( Varyings input ) : SV_TARGET
{
	// Check if the primitives buffer is empty and return the source texture.
	if( _PrimitivesBufferSize == 0 )
	{
		return tex2D(_SourceTexture, input.uv.xy);
	}

	// Convert the depth buffer distance from camera view space to world space.
	// This is done by multiplying the eye space depth by the length of the z-normalized ray.
	// Similar to triangles, the view space z-distance between a point and the camera is proportional to the absolute distance.
	float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, input.uv).r);
	depth *= length(input.ray.xyz);

	// Calculate the ray origin and direction to perform the marching.
	float3 rayOrigin = _CameraPositionWS; // Used instead of _WorldSpaceCameraPos to also raymarch over the editor scene camera.
	float3 rayDirection = normalize(input.ray.xyz);

	return Raymarch(rayOrigin, rayDirection, input.uv, depth);
}

#endif