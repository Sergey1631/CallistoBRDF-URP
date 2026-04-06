half Callisto_R(half x)
{
    return 2.0 * (1.0 - x);
}
half3 GetCallistoTerminator(half NoL, half LoH, half NoV, half Length, half3 Tint)
{
    half MaskD = 1.0 - pow(1.0 - saturate(LoH), 3);
    half MaskH = 1.0 - pow(1.0 - saturate(NoV), 3);
    half AlphaS = MaskD * MaskH;
    half SmoothEdge = max(AlphaS * Length, 0.001f);
    half S = smoothstep(0.0f, SmoothEdge, NoL);
    return lerp(half3(1,1,1), half3(S, S, S), AlphaS * Tint);
}



half Callisto_H(half CosTheta, half FalloffParam, half CosPhi, half TangentParam)
{
    half n = Callisto_R(FalloffParam);
    half m = Callisto_R(TangentParam);
    half ExpN = 5.0f * n;
    half ExpM = 5.0f * m;
    half Term1 = pow(1.0f - saturate(CosTheta), ExpN);
    half Term2 = pow(saturate(CosPhi), ExpM);
    return Term1 * Term2;
}

half GetProximaDiffuse(half Roughness, half NoL, half VoL)
{
    float Alpha = Roughness * Roughness;
    float CosThetaK = -VoL;
    float TermA = -0.55f * NoL + 0.19f;
    float TermB = 1.0f - sqrt(saturate(CosThetaK));
    float Bracket = (Alpha * TermA * TermB) + 1;
    return NoL * max(0.0f, Bracket);
}

half3 GetCallistoC1(
    half NoL, half NoV, 
    half PF_Intensity, half3 PF_Tint, half NF_Falloff, half MF_TangentFalloff,
    half PR_Intensity, half3 PR_Tint, half NR_Falloff, half MR_TangentFalloff
)
{
    half AlphaF = Callisto_H(NoL, NF_Falloff, NoV, MF_TangentFalloff);
    half3 TargetF = PF_Intensity * PF_Tint;
    half3 ComponentF = lerp(half3(1,1,1), TargetF, AlphaF);
    half AlphaR = Callisto_H(NoV, NR_Falloff, NoL, MR_TangentFalloff);
    half3 TargetR = PR_Intensity * PR_Tint;
    half3 ComponentR = lerp(half3(1,1,1), TargetR, AlphaR);
    return ComponentF * ComponentR;
}

half3 Callisto_F_Schlick(half3 f0 , half u, half n_s)
{
    float r = Callisto_R(n_s);
    float exponent = 5.0f * r;
    float t_term = saturate(2.0f - r);
    
    float base = 1.0f - u;
    base = saturate(base);          
    base = max(base, 1e-4);        

    float powTerm = exp2(log2(base) * exponent); 
    return f0 + (1.0f - f0) * (t_term * powTerm);
}


half3 CallistoSpecularGGX(half roughness, half3 specular, half NoL, half NoH, half NoV, half VoH, half SpecularFresnelFalloff)
{
    half r = max(0.01, roughness);
    half a = r * r;
    half a2 = a * a;
    
    real s = (NoH * a2 - NoH) * NoH + 1.0;
    half D = SafeDiv(a2, s * s);
    
    half oneMinusA = 1.0f - a;
    half VisV = NoL * mad(NoV, oneMinusA, a);
    half VisL = NoV * mad(NoL, oneMinusA, a);
    
    half Vis = 0.5f * rcp(VisV + VisL);
    half3 F = Callisto_F_Schlick(specular, VoH, SpecularFresnelFalloff);
    return (D * Vis * F);
}

half3 DualLobeSpecular(half roughnessA, half roughnessB, half mix,
    half specular, half NoL, half NoH, half NoV, half VoH, half SpecularFresnelFalloff)
{
    half aA = max(0.01, roughnessA * roughnessA);
    half aB = max(0.01, roughnessB * roughnessB);

    half D1 = D_GGX(NoH, roughnessA);
    half D2 = D_GGX(NoH, roughnessB);
    
    half Vis1 = V_SmithJointGGXApprox(NoL, NoV, aA );
    half Vis2 = V_SmithJointGGXApprox(NoL, NoV, aB );

    half3 F = Callisto_F_Schlick(specular, VoH, SpecularFresnelFalloff);
    
    half DV = mad(mix, (D2*Vis2 - D1*Vis1), D1*Vis1);
    return DV * F;
}

