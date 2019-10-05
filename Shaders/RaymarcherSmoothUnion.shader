Shader "Raymarching/Raymarcher Smooth Union"
{
	Properties
	{
		_Smooth("Smooth", Range(0, 1)) = 0.5
		[MaterialToggle] _BlendColors("Blend Colors", Int) = 0
	}

	SubShader
	{
		Cull Off
		ZWrite Off
		ZTest Always

		Pass
		{
			HLSLPROGRAM
			#pragma multi_compile _ DEBUG_STEPS
			#pragma multi_compile _ NORMALS_FORWARD_DIFFERENCES NORMALS_TETRAHEDRON
			#pragma multi_compile _ AMBIENT
			#pragma multi_compile _ SPECULAR
			#pragma multi_compile _ AMBIENT_OCCLUSION
			#pragma multi_compile _ HARD_SHADOWS SOFT_SHADOWS SOFT_SHADOWS_IMPROVED

			#pragma vertex Vertex
			#pragma fragment Fragment

			#include "Packages/com.adcimon.raymarching/ShaderLibrary/RaymarchingCore.hlsl"

			float _Smooth;
			int _BlendColors;

			// Implement this function to create the signed distance field.
			RaymarchData SignedDistanceField( float3 position )
			{
				RaymarchData data;
				float mind = 0;

				for( int i = 0; i < _PrimitivesBufferSize; i++ )
				{
					SignedDistancePrimitive primitive = _PrimitivesBuffer[i];

					// Transform the position to object space.
					float3 p = mul(primitive.transform, float4(position, 1)).xyz;

					// Calculate the distance.
					float d = SignedDistanceFunction(primitive, p);

					if( i == 0 )
					{
						data.distance = d;

						data.color = primitive.color;
						data.shininess = primitive.shininess;
						data.specularColor = primitive.specularColor;

						mind = data.distance;
					}
					else
					{
						if( _BlendColors == 0 )
						{
							data.distance = opSmoothUnion(data.distance, d, _Smooth);
						}
						else
						{
							float4 c;
							data.distance = opSmoothUnionColor(data.distance, d, _Smooth, data.color, primitive.color, c);
							data.color = c;
						}

						if( d < mind )
						{
							if( _BlendColors == 0 )
							{
								data.color = primitive.color;
							}

							data.shininess = primitive.shininess;
							data.specularColor = primitive.specularColor;
							mind = d;
						}
					}
				}

				return data;
			}
			ENDHLSL
		}
	}
}