# Callisto BRDF for URP

<img width="900" alt="Callisto Front Face" src="/Documentation/images/BRDFPreview.png" />

Callisto BRDF experimental implementation in Unity Universal Render Pipeline.

Tested on Unity 6000.3.8.f1 and URP 17.3.0

![BRDF Parameteres](/Documentation/images/BRDFSettings.png)

Based on Unreal Engine Vite Fork implementation.

## Installation
* Go to "Window" -> "Package Manager".
* In Package Manager click "+" at the top left corner, and select "Install package from git URL". 
* Write the following URL: `https://github.com/Sergey1631/CallistoBRDF-URP.git` and click install.

![Installation](/Documentation/images/Installation.png)

You can use it by selecting `CallistoBRDF/Lit` shader on material.

![ShaderName](/Documentation/images/ShaderName.png)

## Notes
* This shader uses `UniversalForwardOnly` pass because we cant pack all BRDF parameters in GBuffer.
### Dual Lobe Specular (unconfident and experimental)
* Since URP doesn't support Subsurface Scattering (like HDRP), dual lobe specular is implemented differently using Clear Coat. 
The second lobe is simply a clear coat layer with its own smoothness and mask. 
The lobes' blending is controlled by the `Dual Lobe Mix` property.

## Credits
* [The Character Rendering Art of 'The Callisto Protocol'](https://advances.realtimerendering.com/s2023/SIGGRAPH2023-Advances-The-Rendering-of-The-Callisto-Protocol-JimenezPetersen.pdf)
* [@mad-ben](https://github.com/mad-ben) - Original BRDF implementation in UE
* [@GapingPixel](https://github.com/GapingPixel) - Optimized Vite Fork version
* [Unreal Engine Vite Fork BRDF Code](https://github.com/GapingPixel/UnrealEngineVite-PhysX/blob/2960b9ca3d67e48ada0ae20c56bde220b139a7b2/Engine/Shaders/Private/ShadingModels.ush)
