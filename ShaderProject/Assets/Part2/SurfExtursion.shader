﻿Shader "Custom/SurfExtursion"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Amount("Extrusion Amount", Range(-0.0001, 0.0001)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        
        #pragma surface surf Lambert vertex:vert

        struct Input
        {
            float2 uv_MainTex;
        };

        sampler2D _MainTex;
        float _Amount;
        
        ///顶点修改器
        void vert(inout appdata_full v)
        {
            v.vertex.xyz = v.vertex.xyz + v.normal * _Amount;
        }

        ///表面着色器
        void surf(Input IN, inout SurfaceOutput o)
        {
            o.Albedo = tex2D(_MainTex, IN.uv_MainTex).rgb; //half3 = float4.xyz
        }

        ENDCG
    }
    FallBack "Diffuse"
}
