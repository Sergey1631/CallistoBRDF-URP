

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/BSDF.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/AmbientOcclusion.hlsl"
#include "CallistoBRDF.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"

#if defined(LIGHTMAP_ON)
    #define DECLARE_LIGHTMAP_OR_SH(lmName, shName, index) float2 lmName : TEXCOORD##index
    #define OUTPUT_LIGHTMAP_UV(lightmapUV, lightmapScaleOffset, OUT) OUT.xy = lightmapUV.xy * lightmapScaleOffset.xy + lightmapScaleOffset.zw;
    #define OUTPUT_SH4(absolutePositionWS, normalWS, viewDir, OUT, OUT_OCCLUSION)
    #define OUTPUT_SH(normalWS, OUT)
#else
    #define DECLARE_LIGHTMAP_OR_SH(lmName, shName, index) half3 shName : TEXCOORD##index
    #define OUTPUT_LIGHTMAP_UV(lightmapUV, lightmapScaleOffset, OUT)
    #ifdef USE_APV_PROBE_OCCLUSION
        #define OUTPUT_SH4(absolutePositionWS, normalWS, viewDir, OUT, OUT_OCCLUSION) OUT.xyz = SampleProbeSHVertex(absolutePositionWS, normalWS, viewDir, OUT_OCCLUSION)
    #else
        #define OUTPUT_SH4(absolutePositionWS, normalWS, viewDir, OUT, OUT_OCCLUSION) OUT.xyz = SampleProbeSHVertex(absolutePositionWS, normalWS, viewDir)
    #endif
    // Note: This is the legacy function, which does not support APV.
    // Kept to avoid breaking shaders still calling it (UUM-37723)
    #define OUTPUT_SH(normalWS, OUT) OUT.xyz = SampleSHVertex(normalWS)
#endif

///////////////////////////////////////////////////////////////////////////////
//                      Lighting Functions                                   //
///////////////////////////////////////////////////////////////////////////////



half3 LightingCallisto(BRDFData brdfData, BRDFData brdfDataClearCoat,
    half3 lightColor, half3 lightDirectionWS, float lightAttenuation,
    half3 normalWS, half3 viewDirectionWS,
    half clearCoatSmoothness, bool specularHighlightsOff)
{
    //half4 specGloss = SampleMetallicSpecGloss(InputData.u, albedoAlpha.a);
    
    //--DIFFUSE--
    half NdotL = saturate(dot(normalWS, lightDirectionWS)); 
    half NdotV = abs( dot (normalWS , viewDirectionWS )) + 1e-5f; // avoid artifact
    half3 H = SafeNormalize((lightDirectionWS + viewDirectionWS));

    half VdotL = saturate(dot(viewDirectionWS, lightDirectionWS));
    half VdotH = saturate(dot(viewDirectionWS , H ));
    half NdotH = saturate(dot(normalWS , H ));

    
    half3 C1 = GetCallistoC1(
        NdotL,
        NdotV,
        _DiffuseFresnel,
        _DiffuseFresnelTint,
        clamp(_DiffuseFresnelFalloff,0,0.99),
        clamp(_DiffuseFresnelTangentFalloff,0,0.99),
        _Retroreflection,
        _RetroreflectionFresnelTint,
        clamp(_RetroReflectionFalloff,0,0.99),
        clamp(_RetroreflectionTangentFalloff, 0, 0.99)
    );
    half3 TerminatorFactor = GetCallistoTerminator(NdotL, VdotH, NdotV, _TerminatorLength, _TerminatorTint * _SmoothTerminator);
    half3 SmoothedNoL = NdotL * TerminatorFactor;
    half3 diffuse = C1 * GetProximaDiffuse(brdfData.roughness, SmoothedNoL, VdotL);

    half3 radiance = (lightAttenuation) * SmoothedNoL * lightColor;
    half3 brdf = brdfData.diffuse * diffuse;
    
    //--SPECULAR--
#ifndef _SPECULARHIGHLIGHTS_OFF
    [branch] if (!specularHighlightsOff)
    {
        brdf += NdotL * CallistoSpecularGGX(brdfData.perceptualRoughness,brdfData.specular,NdotL, NdotH, NdotV, VdotH, clamp(_SpecularFresnelFalloff,0,0.99));

        
 #if defined(_CLEARCOAT) || defined(_CLEARCOATMAP)
        half r = clamp(1-clearCoatSmoothness, 0.01, 0.99);
        brdf += DualLobeSpecular(brdfData.perceptualRoughness, r , _LobeMix, brdfData.specular,NdotL, NdotH, NdotV, VdotH, clamp(_SpecularFresnelFalloff,0,0.99)) * SmoothedNoL;
 #endif // _CLEARCOAT
    }
#endif // _SPECULARHIGHLIGHTS_OFF
    return brdf * radiance;
    
}


half3 LightingCallisto(BRDFData brdfData, BRDFData brdfDataClearCoat, Light light, half3 normalWS, half3 viewDirectionWS, half clearCoatSmoothness, bool specularHighlightsOff)
{
    return LightingCallisto(brdfData, brdfDataClearCoat, light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS, clearCoatSmoothness, specularHighlightsOff);
}



half3 CallistoVertexLighting(float3 positionWS, half3 normalWS, half3 viewDirectionWS, half roughness)
{
    half3 vertexLightColor = half3(0.0, 0.0, 0.0);

#ifdef _ADDITIONAL_LIGHTS_VERTEX
    uint lightsCount = GetAdditionalLightsCount();
    uint meshRenderingLayers = GetMeshRenderingLayer();

    LIGHT_LOOP_BEGIN(lightsCount)
        Light light = GetAdditionalLight(lightIndex, positionWS);

#ifdef _LIGHT_LAYERS
    if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
    {
        half3 lightColor = light.color * light.distanceAttenuation;
        half3 lightDirectionWS = Light.direction;
        half NdotL = saturate(dot(normalWS, lightDirectionWS)); 
        half NdotV = abs( dot (normalWS , viewDirectionWS )) + 1e-5f; 
        half3 H = normalize (viewDirectionWS + lightDirectionWS);
        half LdotH = saturate ( dot (lightDirectionWS , H ));
        half NdotH = saturate ( dot (normalWS , H ));

        half3 C1 = GetCallistoC1(
        NdotL,
        NdotV,
        _DiffuseFresnel,
        _DiffuseFresnelTint,
        clamp(_DiffuseFresnelFalloff,0,0.99),
        clamp(_DiffuseFresnelTangentFalloff,0,0.99),
        _Retroreflection,
        _RetroreflectionFresnelTint,
        clamp(_RetroReflectionFalloff,0,0.99),
        clamp(_RetroreflectionTangentFalloff, 0, 0.99)
         );
        half3 TerminatorFactor = GetCallistoTerminator(NdotL, VdotH, NdotV, _TerminatorLength, _TerminatorTint * _SmoothTerminator);
        half3 SmoothedNoL = NdotL * TerminatorFactor;

        half3 diffuse = C1 * NdotL * GetProximaDiffuse(roughness, SmoothedNoL, VdotL);
        
        vertexLightColor += lightColor * diffuse;
    }

    LIGHT_LOOP_END
#endif

    return vertexLightColor;
}




half4 CallistoFragment(InputData inputData, SurfaceData surfaceData)
{
    #if defined(_SPECULARHIGHLIGHTS_OFF)
    bool specularHighlightsOff = true;
    #else
    bool specularHighlightsOff = false;
    #endif
    BRDFData brdfData;

    // NOTE: can modify "surfaceData"...
    InitializeBRDFData(surfaceData, brdfData);

    #if defined(DEBUG_DISPLAY)
    half4 debugColor;

    if (CanDebugOverrideOutputColor(inputData, surfaceData, brdfData, debugColor))
    {
        return debugColor;
    }
    #endif

    // Clear-coat calculation...
    BRDFData brdfDataClearCoat = CreateClearCoatBRDFData(surfaceData, brdfData);
    InitializeBRDFData(surfaceData, brdfDataClearCoat);
    half4 shadowMask = CalculateShadowMask(inputData);
    AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData, surfaceData);
    uint meshRenderingLayers = GetMeshRenderingLayer();
    Light mainLight = GetMainLight(inputData, shadowMask, aoFactor);

    // NOTE: We don't apply AO to the GI here because it's done in the lighting calculation below...
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);

    LightingData lightingData = CreateLightingData(inputData, surfaceData);

    lightingData.giColor = GlobalIllumination(brdfData, brdfDataClearCoat, surfaceData.clearCoatMask,
                                              inputData.bakedGI, aoFactor.indirectAmbientOcclusion, inputData.positionWS,
                                              inputData.normalWS, inputData.viewDirectionWS, inputData.normalizedScreenSpaceUV);
#ifdef _LIGHT_LAYERS
    if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
#endif
    {
        lightingData.mainLightColor = LightingCallisto(brdfData, brdfDataClearCoat,
                                                              mainLight,
                                                              inputData.normalWS, inputData.viewDirectionWS,
                                                              surfaceData.clearCoatSmoothness * _ClearCoatMask, specularHighlightsOff);

        
    }

    #if defined(_ADDITIONAL_LIGHTS)
    uint pixelLightCount = GetAdditionalLightsCount();

    #if USE_CLUSTER_LIGHT_LOOP
    [loop] for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
    {
        CLUSTER_LIGHT_LOOP_SUBTRACTIVE_LIGHT_CHECK

        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

#ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
        {
            lightingData.additionalLightsColor += LightingCallisto(brdfData, brdfDataClearCoat, light,
                                                                          inputData.normalWS, inputData.viewDirectionWS,
                                                                          surfaceData.clearCoatSmoothness * _ClearCoatMask, specularHighlightsOff);
        }
    }
    #endif

    LIGHT_LOOP_BEGIN(pixelLightCount)
        Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);

#ifdef _LIGHT_LAYERS
        if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
        {
            lightingData.additionalLightsColor += LightingCallisto(brdfData, brdfDataClearCoat, light,
                                                                          inputData.normalWS, inputData.viewDirectionWS,
                                                                          surfaceData.clearCoatSmoothness * _ClearCoatMask, specularHighlightsOff);
        }
    LIGHT_LOOP_END
    #endif

    #if defined(_ADDITIONAL_LIGHTS_VERTEX)
    lightingData.vertexLightingColor += inputData.vertexLighting * brdfData.diffuse;
    #endif

#if REAL_IS_HALF
    // Clamp any half.inf+ to HALF_MAX
    return min(CalculateFinalColor(lightingData, surfaceData.alpha), HALF_MAX);
#else
    return CalculateFinalColor(lightingData, surfaceData.alpha);
#endif
}
