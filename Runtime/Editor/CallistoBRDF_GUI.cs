
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;

namespace UnityEditor.Rendering.Universal.ShaderGUI
{
    public class CallistoBRDF_GUI
    {

        public struct CallistoBRDFProperties
        {
            public MaterialProperty lobeMix;
            
            public MaterialProperty smoothTerminator;
            public MaterialProperty terminatorLength;               
            public MaterialProperty diffuseFresnel;
            public MaterialProperty diffuseFresnelFalloff;
            public MaterialProperty retroreflection;
            public MaterialProperty retroReflectionFalloff;

            
            public MaterialProperty specularFresnelFalloff;
            public MaterialProperty terminatorTint;
            public MaterialProperty retroreflectionFresnelTint; 

            public MaterialProperty diffuseFresnelTint;
            public MaterialProperty retroreflectionTangentFalloff;
            public MaterialProperty diffuseFresnelTangentFalloff;

            public CallistoBRDFProperties(MaterialProperty[] properties)
            {
                lobeMix = BaseShaderGUI.FindProperty("_LobeMix", properties, false);
                
                terminatorLength = BaseShaderGUI.FindProperty("_TerminatorLength", properties, false);
                smoothTerminator = BaseShaderGUI.FindProperty("_SmoothTerminator", properties, false);

                
                diffuseFresnel = BaseShaderGUI.FindProperty("_DiffuseFresnel", properties, false);
                diffuseFresnelFalloff = BaseShaderGUI.FindProperty("_DiffuseFresnelFalloff", properties, false);
                retroreflection = BaseShaderGUI.FindProperty("_Retroreflection", properties, false);
                retroReflectionFalloff = BaseShaderGUI.FindProperty("_RetroReflectionFalloff", properties, false);
                
                specularFresnelFalloff = BaseShaderGUI.FindProperty("_SpecularFresnelFalloff", properties, false);
                terminatorTint = BaseShaderGUI.FindProperty("_TerminatorTint", properties, false);
                retroreflectionFresnelTint = BaseShaderGUI.FindProperty("_RetroreflectionFresnelTint", properties, false);

                diffuseFresnelTint = BaseShaderGUI.FindProperty("_DiffuseFresnelTint", properties, false);
                retroreflectionTangentFalloff = BaseShaderGUI.FindProperty("_RetroreflectionTangentFalloff", properties, false);
                diffuseFresnelTangentFalloff = BaseShaderGUI.FindProperty("_DiffuseFresnelTangentFalloff", properties, false);

            }
        }
        

        


        public static void DoCallistoBRDFArea(CallistoBRDFProperties properties, MaterialEditor materialEditor)
        {
            materialEditor.RangeProperty(properties.smoothTerminator, "Smooth Terminator"); 
            materialEditor.RangeProperty(properties.terminatorLength, "Terminator Length"); 
            
            materialEditor.FloatProperty(properties.diffuseFresnel, "Diffuse Fresnel");
            materialEditor.RangeProperty(properties.diffuseFresnelFalloff, "Diffuse Fresnel Falloff");
            materialEditor.FloatProperty(properties.retroreflection, "Retroreflection");
            materialEditor.RangeProperty(properties.retroReflectionFalloff, "Retro Reflection Falloff");
            materialEditor.RangeProperty(properties.specularFresnelFalloff, "Specular Fresnel Falloff");
            
            materialEditor.ColorProperty(properties.terminatorTint, "Terminator Tint");
            materialEditor.ColorProperty(properties.retroreflectionFresnelTint, "Retroreflection Fresnel Tint");
            materialEditor.ColorProperty(properties.diffuseFresnelTint, "Diffuse Fresnel Tint");
            
            materialEditor.RangeProperty(properties.retroreflectionTangentFalloff, "Retroreflection Tangent Falloff");
            materialEditor.RangeProperty(properties.diffuseFresnelTangentFalloff, "Diffuse Fresnel Tangent Falloff");
            
 
            materialEditor.RangeProperty(properties.lobeMix, "Dual Lobe Mix"); 


        }
        
    }
}
