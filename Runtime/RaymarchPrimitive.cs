using UnityEngine;

[ExecuteInEditMode]
[DisallowMultipleComponent]
public class RaymarchPrimitive : MonoBehaviour
{
    public SignedDistancePrimitive primitive = new SignedDistancePrimitive();

    private void Awake()
    {
        UpdatePrimitive();
    }

    private void OnValidate()
    {
        UpdatePrimitive();
    }

    private void Update()
    {
        if( transform.hasChanged )
        {
            UpdatePrimitive();
            transform.hasChanged = false;
        }
    }

    private void UpdatePrimitive()
    {
        primitive.transform = Matrix4x4.TRS(transform.position, transform.rotation, Vector3.one).inverse;
        primitive.scale = transform.lossyScale.x;
    }
}