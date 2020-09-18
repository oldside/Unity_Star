CBUFFER_START(UnityPerMaterial)
float _RaidalBlurOffset;
float4 _MainTex_TexelSize;
float3 _StarPositionVS;
int _RaidalBlurSampleCount;
float _RaidalBlurThreshold;
half _RaidalBlurAttenuation;

CBUFFER_END