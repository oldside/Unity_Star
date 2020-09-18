Shader "MyShaders/Star/Star_Parallax"
{
	Properties
	{
		_MainTex("Color", 2D) = "white" {}
		_Intensity("Intensity",float) = 1
		[NoScaleOffset]_DepthTex("Depth", 2D) = "black" {}
		_MaxLayerNum("MaxLayerNum",float) = 1
		_MinLayerNum("MinLayerNum",float) = 1
		_HeightScale("HeightScale",float) = 1
		_RotationSpeed("RotationSpeed",float) = 1
		[NoScaleOffset]_FlowMap("FlowMap", 2D) = "black" {}
		_FlowIntensity("FlowIntensity", float) = 1
		_FlowSpeed("FlowSpeed", float) = 1
		_RimLight("RimLight", float) = 1
		_RimLightRange("RimLightRange", float) = 1
		_RimLightColor("RimLightColor",Color) = (1,1,1,1)
	}
		SubShader
		{
			Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}

			LOD 200

			Pass
			{
				Name "ForwardLit"
				Tags{"LightMode" = "UniversalForward"}

				Cull Back
				HLSLPROGRAM

				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

				#pragma vertex vert
				#pragma fragment frag

				CBUFFER_START(UnityPerMaterial)
				float _Intensity;
				float4 _MainTex_ST;
				float _MaxLayerNum;
				float _MinLayerNum;
				float _HeightScale;
				float _RotationSpeed;
				float _FlowIntensity;
				float _FlowSpeed;
				float _RimLight;
				float3 _RimLightColor;
				float _RimLightRange;
				CBUFFER_END

				TEXTURE2D(_DepthTex);
				SAMPLER(sampler_DepthTex);

				TEXTURE2D(_MainTex);
				SAMPLER(sampler_MainTex);
				
				TEXTURE2D(_FlowMap);
				SAMPLER(sampler_FlowMap);
				struct Attributes
				{
					float4 tangentOS	    : TANGENT;
					float3 normalOS			: NORMAL;
					float4 positionOS       : POSITION;
					float2 uv               : TEXCOORD0;
				};

				struct Varyings
				{
					float2 uv				: TEXCOORD0;
					float3 posWS			: TEXCOORD1;

					float4 normal			: TEXCOORD3;
					float4 tangent          : TEXCOORD4;
					float4 bitangent        : TEXCOORD5;

					float4 positionCS		: SV_POSITION;
					UNITY_VERTEX_OUTPUT_STEREO
				};


				//视差效果，关于该函数的详细解释参见 https://www.jianshu.com/p/fea6c9fc610f
				float2 ParallaxMapping(float2 uv, float3 viewDirTS)
				{
					float layerNum = lerp(_MaxLayerNum, _MinLayerNum, abs(dot(float3(0, 0, 1), viewDirTS))); //垂直时用更少的样本
					float layerDepth = 1.0 / layerNum;
					float currentLayerDepth = 0.0;
					float2 deltaTexCoords = viewDirTS.xy / viewDirTS.z * _HeightScale / layerNum;

					float2 currentTexCoords = uv;
					float currentDepthMapValue = SAMPLE_TEXTURE2D(_DepthTex, sampler_DepthTex, currentTexCoords).r;

					//unable to unroll loop, loop does not appear to terminate in a timely manner
					//上面这个错误是在循环内使用tex2D导致的，需要加上unroll来限制循环次数或者改用tex2Dlod
					//[unroll(100)]
					while (currentLayerDepth < currentDepthMapValue)
					{
						currentTexCoords -= deltaTexCoords;
						// currentDepthMapValue = tex2D(_DepthMap, currentTexCoords).r;
						currentDepthMapValue = SAMPLE_TEXTURE2D_LOD(_DepthTex, sampler_DepthTex, currentTexCoords,0).r;
						currentLayerDepth += layerDepth;
					}

					float2 prevTexCoords = currentTexCoords + deltaTexCoords;
					float prevLayerDepth = currentLayerDepth - layerDepth;

					float afterDepth = currentDepthMapValue - currentLayerDepth;
					float beforeDepth = SAMPLE_TEXTURE2D(_DepthTex, sampler_DepthTex, prevTexCoords).r - prevLayerDepth;
					float weight = afterDepth / (afterDepth - beforeDepth);
					float2 finalTexCoords = prevTexCoords * weight + currentTexCoords * (1.0 - weight);

					return finalTexCoords;
				}
				
				Varyings vert(Attributes input)
				{
					Varyings output = (Varyings)0;
					UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

					VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
					VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

					half3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;

					output.uv = TRANSFORM_TEX(input.uv, _MainTex);
					output.posWS.xyz = vertexInput.positionWS;
					output.positionCS = vertexInput.positionCS;

					output.normal = half4(normalInput.normalWS, viewDirWS.x);
					output.tangent = half4(normalInput.tangentWS, viewDirWS.y);
					output.bitangent = half4(normalInput.bitangentWS, viewDirWS.z);

					return output;
				}

				half4 frag(Varyings input) : SV_Target
				{
					UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

					float2 uv = input.uv;
					
					float2 flowUV = float2(uv.x + _Time.x*_FlowSpeed, uv.y);
					half3 flowDir = SAMPLE_TEXTURE2D(_FlowMap, sampler_FlowMap, flowUV).xyz*2-1;
					uv -= normalize(flowDir.xy) * _FlowIntensity;

					half3x3 tangentToWorld = half3x3(input.tangent.xyz, input.bitangent.xyz, input.normal.xyz);

					half3 viewDirWS = half3(input.normal.w, input.tangent.w, input.bitangent.w);
					viewDirWS = SafeNormalize(viewDirWS);

					half3 viewDirTS = TransformWorldToTangent(viewDirWS, tangentToWorld);

					half3 normalWS = input.normal.xyz;
					normalWS = SafeNormalize(normalWS);

					half3 normalTS = TransformWorldToTangent(normalWS, tangentToWorld);

					uv.x += _Time.x * _RotationSpeed;
					uv = ParallaxMapping(uv, viewDirTS);
	
					half4 sampleColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);

					half3 rimLight = pow(max(0, 1-dot(viewDirWS, normalWS)), _RimLightRange)* _RimLight * sampleColor.rgb*_RimLightColor;

					half4 finalColor = half4(sampleColor.rgb * _Intensity + rimLight,1);
					
					return finalColor;

				}

				ENDHLSL
			}
// 之前想要通过深度图进行一些骚操作，后来放弃了,URP下如果不添加下面这个Pass，是获取不了该物体的深度信息的
/*
			Pass
			{
				Name "DepthOnly"
				Tags{"LightMode" = "DepthOnly"}

				ZWrite On
				Cull Back
				HLSLPROGRAM

				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

				#pragma prefer_hlslcc gles
				#pragma exclude_renderers d3d11_9x
				#pragma target 2.0

				#pragma vertex DepthOnlyVertex
				#pragma fragment DepthOnlyFragment

				CBUFFER_START(UnityPerMaterial)
				float _Intensity;
				float4 _MainTex_ST;
				float _MaxLayerNum;
				float _MinLayerNum;
				float _HeightScale;
				float _RotationSpeed;
				float _FlowIntensity;
				float _FlowSpeed;
				float _RimLight;
				float3 _RimLightColor;
				float _RimLightRange;

				CBUFFER_END

				TEXTURE2D(_DepthTex);
				SAMPLER(sampler_DepthTex);

				TEXTURE2D(_MainTex);
				SAMPLER(sampler_MainTex);



				struct Attributes
				{
					float4 position     : POSITION;
					float2 texcoord     : TEXCOORD0;
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				struct Varyings
				{
					float2 uv           : TEXCOORD0;
					float4 positionCS   : SV_POSITION;
					UNITY_VERTEX_INPUT_INSTANCE_ID
						UNITY_VERTEX_OUTPUT_STEREO
				};

				Varyings DepthOnlyVertex(Attributes input)
				{
					Varyings output = (Varyings)0;
					UNITY_SETUP_INSTANCE_ID(input);
					UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

					output.uv = input.texcoord;
				
					output.positionCS = TransformObjectToHClip(input.position.xyz);
					return output;
				}

				half4 DepthOnlyFragment(Varyings input) : SV_TARGET
				{
					UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

					Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_MainTex, sampler_MainTex)).a, half4(1,1,1,1), 0.5);
					return 0;
				}

				ENDHLSL
			}
*/
		}
		FallBack "Universal Render Pipeline/Lit"
}
