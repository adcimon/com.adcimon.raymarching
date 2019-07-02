using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(RaymarchPrimitive))]
public class RaymarchPrimitiveInspector : Editor
{
	private RaymarchPrimitive script;

	private void Awake()
	{
		script = (RaymarchPrimitive)target;
	}

	public override void OnInspectorGUI()
	{
        GUILayout.Space(5);
        DrawPrimitiveParameters();
        GUILayout.Space(10);
        DrawPrimitiveMaterial();
        EditorApplication.QueuePlayerLoopUpdate();
        GUILayout.Space(10);
    }

    private void DrawPrimitiveParameters()
    {
        EditorGUILayout.LabelField("Parameters");
        script.primitive.type = (SignedDistancePrimitive.Type)EditorGUILayout.EnumPopup("Type", script.primitive.type);
        switch( script.primitive.type )
        {
            case SignedDistancePrimitive.Type.Plane:            DrawPlaneParameters();              break;
            case SignedDistancePrimitive.Type.Box:              DrawBoxParameters();                break;
            case SignedDistancePrimitive.Type.Sphere:           DrawSphereParameters();             break;
            case SignedDistancePrimitive.Type.Ellipsoid:        DrawEllipsoidParameters();          break;
            case SignedDistancePrimitive.Type.Cylinder:         DrawCylinderParameters();           break;
            case SignedDistancePrimitive.Type.Capsule:          DrawCapsuleParameters();            break;
            case SignedDistancePrimitive.Type.Torus:            DrawTorusParameters();              break;
            case SignedDistancePrimitive.Type.TriangularPrism:  DrawTriangularPrismParameters();    break;
            case SignedDistancePrimitive.Type.HexagonalPrism:   DrawHexagonalPrismParameters();     break;
            default: break;
        }
    }

    private void DrawPrimitiveMaterial()
    {
        EditorGUILayout.LabelField("Material");
        script.primitive.color = EditorGUILayout.ColorField("Color", script.primitive.color);
        script.primitive.shininess = EditorGUILayout.Slider("Shininess", script.primitive.shininess, 0, 100);
        script.primitive.specularColor = EditorGUILayout.ColorField("Specular Color", script.primitive.specularColor);
    }

    private void DrawPlaneParameters()
    {
    }

    private void DrawBoxParameters()
    {
        script.primitive.parameter0 = EditorGUILayout.FloatField("Width", script.primitive.parameter0);
        script.primitive.parameter1 = EditorGUILayout.FloatField("Height", script.primitive.parameter1);
        script.primitive.parameter2 = EditorGUILayout.FloatField("Depth", script.primitive.parameter2);
    }

    private void DrawSphereParameters()
    {
        script.primitive.parameter0 = EditorGUILayout.FloatField("Radius", script.primitive.parameter0);
    }

    private void DrawEllipsoidParameters()
    {
        script.primitive.parameter0 = EditorGUILayout.FloatField("Width", script.primitive.parameter0);
        script.primitive.parameter1 = EditorGUILayout.FloatField("Height", script.primitive.parameter1);
        script.primitive.parameter2 = EditorGUILayout.FloatField("Depth", script.primitive.parameter2);
    }

    private void DrawCylinderParameters()
    {
        script.primitive.parameter0 = EditorGUILayout.FloatField("Height", script.primitive.parameter0);
        script.primitive.parameter1 = EditorGUILayout.FloatField("Radius", script.primitive.parameter1);
    }

    private void DrawCapsuleParameters()
    {
        script.primitive.parameter0 = EditorGUILayout.FloatField("Height", script.primitive.parameter0);
        script.primitive.parameter1 = EditorGUILayout.FloatField("Radius", script.primitive.parameter1);
    }

    private void DrawTorusParameters()
    {
        script.primitive.parameter0 = EditorGUILayout.FloatField("Radius", script.primitive.parameter0);
        script.primitive.parameter1 = EditorGUILayout.FloatField("Width", script.primitive.parameter1);
    }

    private void DrawTriangularPrismParameters()
    {
        script.primitive.parameter0 = EditorGUILayout.FloatField("Size", script.primitive.parameter0);
        script.primitive.parameter1 = EditorGUILayout.FloatField("Depth", script.primitive.parameter1);
    }

    private void DrawHexagonalPrismParameters()
    {
        script.primitive.parameter0 = EditorGUILayout.FloatField("Size", script.primitive.parameter0);
        script.primitive.parameter1 = EditorGUILayout.FloatField("Depth", script.primitive.parameter1);
    }
}