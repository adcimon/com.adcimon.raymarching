# Raymarching

This repository contains a toolkit to render signed distance functions with raymarching in Unity.

## Installation

The toolkit is structured as a Unity package. To install it in your Unity project follow the next steps:

1. Clone the repository on your machine.
2. Open the file `MyUnityProject/Packages/manifest.json` and add the dependency of the cloned package `"com.aquarterofpixel.raymarching": "file:path/to/Raymarching"`.

## How to use it

1. Attach a `Raymarcher` component to the camera.

![](Documentation/add_raymarcher.png)

2. Select the material used to render. Two materials are included in the package, `RaymarcherUnion` and `RaymarcherSmoothUnion`.
3. Add a `RaymarchPrimitive` component to a gameobject.
4. Select the parameters and material used to render the primitive.
5. Add the `RaymarchPrimitive` component to the primitives list of the `Raymarcher` component.
