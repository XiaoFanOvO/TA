﻿// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/GrabShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BumpMap ("Noise text", 2D) = "bump" {}
    }
    SubShader
    {
        Tags
        {
            "Queue" = "Transparent" //透明的物体在不透明的物体之后
            "IgnoreProjector" = "True"
            "RenderType" = "Opaque" // 我们希望不透明物体都在这个物体渲染之前被先渲染完了，这样渲染这个物体的时候抓取的屏幕图像才是正确的屏幕图像
        }
        ZWrite On
        Lighting Off
        Cull Off
        Fog{Mode off}
        Blend One Zero
        LOD 100

        GrabPass{"_GrabTexture"} //在对玻璃第一遍渲染时,把整个场景拍照,绘制到一个名为_GrabTexture的纹理上
        //GrabPass把抓取到的屏幕图像储存在一张与屏幕分辨率相同的RT中

        // 将GrabPass抓取的内容贴图到当前pass
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _GrabTexture; //表示在GrabPass中抓取纹理

            struct VertInput
            {
                float4 vertex : POSITION;
            };

            struct VertOutput
            {
                float4 vertex : POSITION;
                float4 uvgrab : TEXCOORD1;
            };

            //计算每个顶点相关的属性(位置,纹理坐标等)
            VertOutput vert(VertInput v)
            {
                VertOutput o;
                o.vertex = UnityObjectToClipPos(v.vertex); //顶点变换
                //ComputeGrabScreenPos 传入一个投影空间中的顶点坐标,此方法会以摄像机可视范围的左下角为纹理坐标[0,0]点,右上角为[1,1]点
                //计算出当前顶点位置对应的纹理坐标
                o.uvgrab = ComputeGrabScreenPos(o.vertex);
                return o;
                //顶点坐标是-1到1，纹理坐标是0到1
                //在ComputeGrabScreenPos方法中先将顶点坐标全部除以0.5, 再全部加0.5，就转化为了纹理坐标
            }

            //对unity光栅化阶段经过顶点插值得到的片元(像素)的属性进行计算,得到每个片元的颜色值
            half4 frag(VertOutput i) : COLOR
            {
                //tex2Dproj和tex2D的唯一区别是，在对纹理进行采样之前，tex2Dproj将输入的UV xy坐标除以其w坐标。这是将坐标从正交投影转换为透视投影。
                //裁剪空间的坐标经过缩放和偏移后就变成了(0,ｗ),而当分量除以分量W以后,就变成了(0,1),这样在计算需要返回(0,1)值的时候,就可以直接使用tex2Dproj了
                return tex2Dproj(_GrabTexture, i.uvgrab) * 0.5;


                /*
                    结合vert中的代码来看:
                    (i.uvgrab.xy / i.uvgrab.w + 0.5)  (-1,1) * 0.5 => (-0.5, 0.5) + 0.5 = > (0,1)
                    总结：
                    为了体现玻璃半透明的效果，需要抓取整个场景到一张纹理，即GrabTexture
                    然后对GrabTexture进行贴图，但是屏幕贴图怎么把玻璃区域刚好贴到玻璃四边形上呢？（uv和GrabTexture如何对应）
                    顶点的xy坐标除以顶点的齐次坐标值w，得到其在透视投影环境下的位置
                    把投影空间（半立方体空间）中的顶点转换到纹理坐标空间，也即：[-1, +1] => [0 , 1]
                    由于D3D的纹理坐标v是朝下的，而顶点的y坐标是朝上的，所以要做一个转换（* -1） 



                    为了体现玻璃半透明的效果，需要抓取整个场景到一张纹理，即GrabTexture
                    通过顶点变换获得屏幕顶点坐标，再通过ComputeGrabScreenPos方法将（-1,1）的坐标转化为（0,1）的坐标 (-1,1) * 0.5 => (-0.5, 0.5) + 0.5 = > (0,1)
                    此时就获得了GrabTexture上对应的纹理坐标
                    在片元中，根据算好的纹理坐标，将GrabTexture贴在物体上，注意此时需要除以齐次坐标，保证结果是（0,1）
                */

            }

            ENDCG
        }
    }
}
