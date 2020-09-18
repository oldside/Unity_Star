Shader "MyShaders/Star/PostProcess"
{
	Properties
	{
		[HideInInspector][NoScaleOffset]_MainTex("Source", 2D) = "white" {}

		[Header(Raidal Blur)][Space]
			_RaidalBlurOffset("Raidal Blur Offset",Range(0,0.02)) = 1
			_RaidalBlurSampleCount("Sample Count",int) = 6
			_RaidalBlurThreshold("Threshold",float) = 0
			_RaidalBlurAttenuation("Attenuation",Range(0,1)) = 0.5
	}

		SubShader
		{
			Tags { "RenderType" = "Opaque" }

			LOD 200


			Pass
			{
				Name"RaidalBlur"
				HLSLPROGRAM

				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
				#pragma vertex vert
				#pragma fragment frag

				#include "PostProcessInput.hlsl"

				TEXTURE2D(_MainTex);
				SAMPLER(sampler_MainTex);

				struct Attributes
				{
					float4 positionOS       : POSITION;
					float2 uv               : TEXCOORD0;
				};

				struct Varyings
				{
					float2 uv				: TEXCOORD0;
					float2 BlurOffset		: TEXCOORD1;
					float4 positionCS		: SV_POSITION;

				};


				Varyings vert(Attributes input)
				{
					Varyings output = (Varyings)0;

					output.uv = input.uv;
					output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
					output.BlurOffset = _RaidalBlurOffset * (input.uv - _StarPositionVS.xy);

					return output;
				}

				half4 frag(Varyings input) : SV_Target
				{
					float2 uv = input.uv;

					half4 color = 0;
					_RaidalBlurSampleCount = max(0, _RaidalBlurSampleCount);
					
					for (int j = 0; j < _RaidalBlurSampleCount; j++)
					{
						half4 Sample = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
						Sample *= smoothstep(0,_RaidalBlurThreshold, Sample)*pow(abs(_RaidalBlurAttenuation),j);
						//Sample *=_RaidalBlurThreshold*Sample*pow(abs(_RaidalBlurAttenuation), j);
						//Sample *= step(_RaidalBlurThreshold, Sample)*pow(abs(_RaidalBlurAttenuation), j);
						//Sample *= pow(Sample, abs(_RaidalBlurThreshold))*pow(abs(_RaidalBlurAttenuation), j);
						color += Sample;

						uv -= input.BlurOffset;
					}
				
					return color;
				}



				ENDHLSL
			}

			Pass
			{
				Name"GaussianBlurHorizontal"
				HLSLPROGRAM

				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
				#pragma vertex vert
				#pragma fragment frag

				#include "PostProcessInput.hlsl"

				TEXTURE2D(_MainTex);
				SAMPLER(sampler_MainTex);

				struct Attributes
				{
					float4 positionOS       : POSITION;
					float2 uv               : TEXCOORD0;
				};

				struct Varyings
				{
					float2 uv				: TEXCOORD0;
					float4 positionCS		: SV_POSITION;

				};


				Varyings vert(Attributes input)
				{
					Varyings output = (Varyings)0;

					output.uv = input.uv;
					output.positionCS = TransformObjectToHClip(input.positionOS.xyz);

					return output;
				}

				half4 frag(Varyings input) : SV_Target
				{
					float2 uv = input.uv;

					half GaussianCore[5];
					GaussianCore[0] = 0.0545;
					GaussianCore[1] = 0.2442;
					GaussianCore[2] = 0.4026;
					GaussianCore[3] = 0.2442;
					GaussianCore[4] = 0.0545;

					half4 color = 0;
					
					for (int i = 0; i < 5; i++)
					{
						color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(uv.x + _MainTex_TexelSize.x*(i - 2),uv.y)) * GaussianCore[i];
					}
		
					return color;
				}



				ENDHLSL
			}

			Pass
			{
				Name"GaussianBlurVertical"
				HLSLPROGRAM

				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
				#pragma vertex vert
				#pragma fragment frag

				#include "PostProcessInput.hlsl"

				TEXTURE2D(_MainTex);
				SAMPLER(sampler_MainTex);

				struct Attributes
				{
					float4 positionOS       : POSITION;
					float2 uv               : TEXCOORD0;
				};

				struct Varyings
				{
					float2 uv				: TEXCOORD0;
					float4 positionCS		: SV_POSITION;

				};


				Varyings vert(Attributes input)
				{
					Varyings output = (Varyings)0;

					output.uv = input.uv;
					output.positionCS = TransformObjectToHClip(input.positionOS.xyz);

					return output;
				}

				half4 frag(Varyings input) : SV_Target
				{
					float2 uv = input.uv;

					half GaussianCore[5];
					GaussianCore[0] = 0.0545;
					GaussianCore[1] = 0.2442;
					GaussianCore[2] = 0.4026;
					GaussianCore[3] = 0.2442;
					GaussianCore[4] = 0.0545;

					half4 color = 0;

					for (int i = 0; i < 5; i++)
					{
						color += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(uv.x ,uv.y + _MainTex_TexelSize.y*(i - 2))) * GaussianCore[i];
					}

					return color;
				}



				ENDHLSL
			}

				
			Pass
			{
				Name"Overlay"
				Blend One One

				HLSLPROGRAM

				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
				#pragma vertex vert
				#pragma fragment frag

				#include "PostProcessInput.hlsl"

				TEXTURE2D(_MainTex);
				SAMPLER(sampler_MainTex);

				struct Attributes
				{
					float4 positionOS       : POSITION;
					float2 uv               : TEXCOORD0;
				};

				struct Varyings
				{
					float2 uv				: TEXCOORD0;
					float4 positionCS		: SV_POSITION;

				};


				Varyings vert(Attributes input)
				{
					Varyings output = (Varyings)0;

					output.uv = input.uv;
					output.positionCS = TransformObjectToHClip(input.positionOS.xyz);

					return output;
				}

				half4 frag(Varyings input) : SV_Target
				{
					float2 uv = input.uv;


					half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);


					return color;
				}



				ENDHLSL
			}

		}
			FallBack off
}
