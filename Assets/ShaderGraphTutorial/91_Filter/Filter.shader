Shader "Unlit/Filter"
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
            
            float4 frag(v2f input) : SV_Target
            {
                float4 col = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                return col * _TintColor;
            }
            ENDHLSL
        }
    }
}
