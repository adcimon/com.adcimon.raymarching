using System.IO;
using UnityEngine;
using UnityEditor;

public static class RaymarchingEditor
{
    [MenuItem("Assets/Create/Raymarcher Shader")]
    public static void CreateRaymarcherShader()
    {
        string path = AssetDatabase.GetAssetPath(Selection.activeObject);
        if( Path.GetExtension(path) != "" )
        {
            path = path.Replace(Path.GetFileName(AssetDatabase.GetAssetPath(Selection.activeObject)), "");
        }

        string[] folders = path.Split('/');
        path = "";
        for( int i = 0; i < folders.Length; i++ )
        {
            if( folders[i] == "Assets" )
            {
                continue;
            }

            path += "/" + folders[i];
        }

        using( StreamWriter stream = File.CreateText(Application.dataPath + path + "/New Raymarcher Shader.shader") )
        {
            stream.Write(template);
        }

        AssetDatabase.Refresh();
    }

    private static string template = @"Shader ""Raymarching/New Raymarcher Shader""
{
	Properties
	{
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

            #include ""Packages/com.aquarterofpixel.raymarching/ShaderLibrary/RaymarchingCore.hlsl""

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
                        data.distance = opUnion(data.distance, d);

                        if( d < mind )
                        {
                            data.color = primitive.color;
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
    ";
}