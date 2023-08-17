Shader "Unlit/NoiseGenerator"
{
    Properties
    {
        _BaseMap ("Base Map", 2D) = "white" { }
        _TintColor ("Tint Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" "Queue" = "Geometry" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }

            Cull Off
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _TintColor;
            CBUFFER_END

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;

                o.vertex = float4(v.vertex.xy * 2., 0.5, 1.0);

                o.uv = v.uv;

                // Direct3DのようにUVの上下が反転したプラットフォームを考慮します
                #if UNITY_UV_STARTS_AT_TOP
                    o.uv.y = 1 - o.uv.y;
                #endif

                return o;
            }

            // Tileable Gradient Noise by ming
            // https://www.shadertoy.com/view/wtsyWf

            // iq's gradient noise https://www.shadertoy.com/view/Xsl3Dl

            //----------------------------------------------------------------------------------------
            float3 HashALU(in float3 p, in float numCells)
            {
                // This is tiling part, adjusts with the scale
                p = fmod(p, numCells);

                p = float3(dot(p, float3(127.1, 311.7, 74.7)),
                dot(p, float3(269.5, 183.3, 246.1)),
                dot(p, float3(113.5, 271.9, 124.6)));

                return -1.0 + 2.0 * frac(sin(p) * 43758.5453123);
            }

            #define Hash HashALU
            // #define Hash HashTex

            //----------------------------------------------------------------------------------------
            float Noise(in float3 p, in float numCells)
            {
                float3 f, i;

                p *= numCells;


                f = frac(p);		// Separate integer from fractional
                i = floor(p);

                float3 u = f * f * (3.0 - 2.0 * f); // Cosine interpolation approximation

                return lerp(lerp(lerp(dot(Hash(i + float3(0.0, 0.0, 0.0), numCells), f - float3(0.0, 0.0, 0.0)),
                dot(Hash(i + float3(1.0, 0.0, 0.0), numCells), f - float3(1.0, 0.0, 0.0)), u.x),
                lerp(dot(Hash(i + float3(0.0, 1.0, 0.0), numCells), f - float3(0.0, 1.0, 0.0)),
                dot(Hash(i + float3(1.0, 1.0, 0.0), numCells), f - float3(1.0, 1.0, 0.0)), u.x), u.y),
                lerp(lerp(dot(Hash(i + float3(0.0, 0.0, 1.0), numCells), f - float3(0.0, 0.0, 1.0)),
                dot(Hash(i + float3(1.0, 0.0, 1.0), numCells), f - float3(1.0, 0.0, 1.0)), u.x),
                lerp(dot(Hash(i + float3(0.0, 1.0, 1.0), numCells), f - float3(0.0, 1.0, 1.0)),
                dot(Hash(i + float3(1.0, 1.0, 1.0), numCells), f - float3(1.0, 1.0, 1.0)), u.x), u.y), u.z);
            }

            //----------------------------------------------------------------------------------------
            // numCells better be power of two
            float NoiseFBM(in float3 p, float numCells, int octaves)
            {
                float f = 0.0;

                // Change starting scale to any integer value...
                p = fmod(p, float3(numCells, numCells, numCells));
                float amp = 0.5;
                float sum = 0.0;

                for (int i = 0; i < octaves; i++)
                {
                    f += Noise(p, numCells) * amp;
                    sum += amp;
                    amp *= 0.5;

                    // numCells must be multiplied by an integer value...
                    numCells *= 2.0;
                }

                return f / sum;
            }

            float4 frag(v2f input) : SV_Target
            {
                // float4 col = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                float noise = NoiseFBM(float3(input.uv, 0), 10, 10) + 0.5;
                // noise /= 2;
                // float noise = HashALU(floor(float3(input.uv, 0) * 64) / 64, 10);

                return float4(noise, noise, noise, 1);
            }
            ENDHLSL
        }
    }
}
