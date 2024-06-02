using System;
using UnityEngine;

[Serializable]
public struct SignedDistancePrimitive
{
	public enum Type
	{
		Plane = 0,
		Box = 1,
		Sphere = 2,
		Ellipsoid = 3,
		Cylinder = 4,
		Capsule = 5,
		Torus = 6,
		TriangularPrism = 7,
		HexagonalPrism = 8
	}

	public Type type;
	public Matrix4x4 transform;
	public float scale;
	public float parameter0;
	public float parameter1;
	public float parameter2;
	public Color color;
	public float shininess;
	public Color specularColor;
}