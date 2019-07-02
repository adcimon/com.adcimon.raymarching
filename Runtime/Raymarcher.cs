using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;

[ImageEffectAllowedInSceneView]
[ExecuteInEditMode]
[DisallowMultipleComponent]
[RequireComponent(typeof(Camera))]
public class Raymarcher : MonoBehaviour
{
    public enum Normals
    {
        ForwardDifferences = 0,
        CentralDifferences = 1,
        Tetrahedron = 2
    }

    public enum Shadows
    {
        Off = 0,
        HardShadows = 1,
        SoftShadows = 2,
        SoftShadowsImproved = 3
    }

    [Header("Raymarching")]
    public Material material;
    public int steps = 64;
    public float minDistance = 0.01f;
    public float maxDistance = 1000;
    public float normalOffset = 0.01f;
    public bool debugSteps = false;

    [Header("Lighting")]
    public Normals normals = Normals.CentralDifferences;
    public bool ambient = true;
    public bool ambientSky = false;
    public Color ambientColor = new Color(0.212f, 0.227f, 0.259f, 1);
    public bool specular = true;

    [Header("Shadows")]
    public Shadows shadows = Shadows.SoftShadows;
    public Vector2 shadowDistance = new Vector2(0.1f, 100);
    [Range(0, 4)] public float shadowIntensity = 1;
    [Range(1, 128)] public float shadowPenumbra = 1;

    [Header("Ambient Occlusion")]
    public bool ambientOcclusion = true;
    [Range(0.01f, 10)] public float ambientOcclusionStepSize = 0.1f;
    [Range(1, 5)] public int ambientOcclusionIterations = 1;
    [Range(0, 1)] public float ambientOcclusionIntensity = 0;

    [Space(10)]
    public List<RaymarchPrimitive> primitives = new List<RaymarchPrimitive>();

    // Compute buffer used to store the primitives.
    private int primitivesBufferSize = 0;
    private ComputeBuffer primitivesBuffer;

    private void Awake()
    {
        // Set the campera texture mode to generate also the depth buffer.
        Camera camera = Camera.current;
        if( camera )
        {
            camera.depthTextureMode = DepthTextureMode.Depth;
        }
    }

    private void OnValidate()
    {
        UpdatePrimitivesBuffer();
    }

    private void LateUpdate()
    {
        UpdatePrimitivesBuffer();
    }

    private void OnRenderImage( RenderTexture source, RenderTexture destination )
    {
        if( !material )
        {
            Graphics.Blit(source, destination);
            return;
        }

        // Pass the uniform variables to the material.
        SetMaterialProperties(source);

        RenderTexture.active = destination;

        GL.PushMatrix();
        GL.LoadOrtho();
        material.SetPass(0);

        // Create a quad to perform the raymarching.
        GL.Begin(GL.QUADS);
        {
            // The z values are indices to the camera frustum vectors.

            // Bottom Left.
            GL.MultiTexCoord2(0, 0, 0);
            GL.Vertex3(0, 0, 3);

            // Bottom Right.
            GL.MultiTexCoord2(0, 1, 0);
            GL.Vertex3(1, 0, 2);

            // Top Right.
            GL.MultiTexCoord2(0, 1, 1);
            GL.Vertex3(1, 1, 1);

            // Top Left.
            GL.MultiTexCoord2(0, 0, 1);
            GL.Vertex3(0, 1, 0); 
        }
        GL.End();

        GL.PopMatrix();
    }

    private void OnDestroy()
    {
        FreePrimitivesBuffer();
    }

    private void SetMaterialProperties( RenderTexture source )
    {
        // Raymarching.
        material.SetInt("_Steps", steps);
        material.SetFloat("_MinDistance", minDistance);
        material.SetFloat("_MaxDistance", maxDistance);
        material.SetFloat("_NormalOffset", normalOffset);
        if( debugSteps && !material.IsKeywordEnabled("DEBUG_STEPS") ) material.EnableKeyword("DEBUG_STEPS");
        if( !debugSteps && material.IsKeywordEnabled("DEBUG_STEPS") ) material.DisableKeyword("DEBUG_STEPS");

        // Camera.
        Camera camera = Camera.current;
        material.SetVector("_CameraPositionWS", camera.transform.position);
        material.SetMatrix("_CameraViewToWorld", camera.cameraToWorldMatrix);
        material.SetMatrix("_CameraFrustum", CameraFrustum(camera));
        material.SetTexture("_SourceTexture", source);

        // Lighting.

        // Normals.
        switch( normals )
        {
            case Normals.CentralDifferences:
            {
                if( material.IsKeywordEnabled("NORMALS_FORWARD_DIFFERENCES") )      material.DisableKeyword("NORMALS_FORWARD_DIFFERENCES");
                if( material.IsKeywordEnabled("NORMALS_TETRAHEDRON") )              material.DisableKeyword("NORMALS_TETRAHEDRON");
                break;
            }
            case Normals.ForwardDifferences:
            {
                if( !material.IsKeywordEnabled("NORMALS_FORWARD_DIFFERENCES") )     material.EnableKeyword("NORMALS_FORWARD_DIFFERENCES");
                if( material.IsKeywordEnabled("NORMALS_TETRAHEDRON") )              material.DisableKeyword("NORMALS_TETRAHEDRON");
                break;
            }
            case Normals.Tetrahedron:
            {
                if( material.IsKeywordEnabled("NORMALS_FORWARD_DIFFERENCES") )      material.DisableKeyword("NORMALS_FORWARD_DIFFERENCES");
                if( !material.IsKeywordEnabled("NORMALS_TETRAHEDRON") )             material.EnableKeyword("NORMALS_TETRAHEDRON");
                break;
            }
        }

        // Ambient.
        if ( ambientSky ) material.SetColor("_AmbientColor", RenderSettings.ambientSkyColor); // Same value as ambientLight.
        else material.SetColor("_AmbientColor", ambientColor);

        if( ambient && !material.IsKeywordEnabled("AMBIENT") ) material.EnableKeyword("AMBIENT");
        if( !ambient && material.IsKeywordEnabled("AMBIENT") ) material.DisableKeyword("AMBIENT");

        // Specular.
        if( specular && !material.IsKeywordEnabled("SPECULAR") ) material.EnableKeyword("SPECULAR");
        if( !specular && material.IsKeywordEnabled("SPECULAR") ) material.DisableKeyword("SPECULAR");

        // Shadows.
        material.SetVector("_ShadowDistance", shadowDistance);
        material.SetFloat("_ShadowIntensity", shadowIntensity);
        material.SetFloat("_ShadowPenumbra", shadowPenumbra);
        switch( shadows )
        {
            case Shadows.Off:
            {
                if( material.IsKeywordEnabled("HARD_SHADOWS") )             material.DisableKeyword("HARD_SHADOWS");
                if( material.IsKeywordEnabled("SOFT_SHADOWS") )             material.DisableKeyword("SOFT_SHADOWS");
                if( material.IsKeywordEnabled("SOFT_SHADOWS_IMPROVED") )    material.DisableKeyword("SOFT_SHADOWS_IMPROVED");
                break;
            }
            case Shadows.HardShadows:
            {
                if( !material.IsKeywordEnabled("HARD_SHADOWS") )            material.EnableKeyword("HARD_SHADOWS");
                if( material.IsKeywordEnabled("SOFT_SHADOWS") )             material.DisableKeyword("SOFT_SHADOWS");
                if( material.IsKeywordEnabled("SOFT_SHADOWS_IMPROVED") )    material.DisableKeyword("SOFT_SHADOWS_IMPROVED");
                break;
            }
            case Shadows.SoftShadows:
            {
                if( material.IsKeywordEnabled("HARD_SHADOWS") )             material.DisableKeyword("HARD_SHADOWS");
                if( !material.IsKeywordEnabled("SOFT_SHADOWS") )            material.EnableKeyword("SOFT_SHADOWS");
                if( material.IsKeywordEnabled("SOFT_SHADOWS_IMPROVED") )    material.DisableKeyword("SOFT_SHADOWS_IMPROVED");
                break;
            }
            case Shadows.SoftShadowsImproved:
            {
                if( material.IsKeywordEnabled("HARD_SHADOWS") )             material.DisableKeyword("HARD_SHADOWS");
                if( material.IsKeywordEnabled("SOFT_SHADOWS") )             material.DisableKeyword("SOFT_SHADOWS");
                if( !material.IsKeywordEnabled("SOFT_SHADOWS_IMPROVED") )   material.EnableKeyword("SOFT_SHADOWS_IMPROVED");
                break;
            }
        }

        // Ambient Occlusion.
        material.SetFloat("_AmbientOcclusionStepSize", ambientOcclusionStepSize);
        material.SetInt("_AmbientOcclusionIterations", ambientOcclusionIterations);
        material.SetFloat("_AmbientOcclusionIntensity", ambientOcclusionIntensity);
        if( ambientOcclusion && !material.IsKeywordEnabled("AMBIENT_OCCLUSION") ) material.EnableKeyword("AMBIENT_OCCLUSION");
        if( !ambientOcclusion && material.IsKeywordEnabled("AMBIENT_OCCLUSION") ) material.DisableKeyword("AMBIENT_OCCLUSION");

        // Primitives.
        material.SetInt("_PrimitivesBufferSize", primitivesBufferSize);
        material.SetBuffer("_PrimitivesBuffer", primitivesBuffer);
    }

    private Matrix4x4 CameraFrustum( Camera camera )
    {
        Matrix4x4 frustum = Matrix4x4.identity;

        float fov = Mathf.Tan((camera.fieldOfView * 0.5f) * Mathf.Deg2Rad);

        Vector3 up = Vector3.up * fov;
        Vector3 right = Vector3.right * fov * camera.aspect;

        Vector3 topLeft = -Vector3.forward - right + up;
        Vector3 topRight = -Vector3.forward + right + up;
        Vector3 bottomRight = -Vector3.forward + right - up;
        Vector3 bottomLeft = -Vector3.forward - right - up;

        // The index of each row is passed to the GPU in the z position of each vertex attribute.
        frustum.SetRow(0, topLeft);
        frustum.SetRow(1, topRight);
        frustum.SetRow(2, bottomRight);
        frustum.SetRow(3, bottomLeft);

        return frustum;
    }

    private void UpdatePrimitivesBuffer()
    {
        List<SignedDistancePrimitive> prims = new List<SignedDistancePrimitive>();
        for( int i = 0; i < primitives.Count; i++ )
        {
            RaymarchPrimitive raymarchObject = primitives[i];
            if( !raymarchObject )
            {
                continue;
            }

            prims.Add(raymarchObject.primitive);
        }

        // Check the number of primitives.
        if( prims.Count == 0 )
        {
            primitivesBufferSize = 0;
            return;
        }

        FreePrimitivesBuffer();
        primitivesBufferSize = prims.Count;
        primitivesBuffer = new ComputeBuffer(primitivesBufferSize, Marshal.SizeOf(typeof(SignedDistancePrimitive)), ComputeBufferType.Default);
        primitivesBuffer.SetData(prims);
    }

    private void FreePrimitivesBuffer()
    {
        primitivesBuffer?.Release();
        primitivesBuffer?.Dispose();
        primitivesBuffer = null;
    }
}