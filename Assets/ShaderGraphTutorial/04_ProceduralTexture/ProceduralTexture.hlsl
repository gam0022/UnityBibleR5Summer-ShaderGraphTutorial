// インクルードガード（TypeがFileのCustom Functionには必要）
#ifndef PROCEDURAL_TEXTURE_INCLUDE
#define PROCEDURAL_TEXTURE_INCLUDE

#define BPM 120.0
#define beat (_Time.y * BPM / 60.0)
float beatTau;
float beatPhase;

// イージングしながら階段のように単調増加する関数
#define phase(x) (floor(x) + .5 + .5 * cos(PI * exp(-5.0 * frac(x))))

// ランダムな値を計算
float hash12(float2 p)
{
    float3 p3 = frac(float3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return frac((p3.x + p3.y) * p3.z);
}

// 正剰余のmod（HLSLのfmodは負剰余）
float mod(float x, float y)
{
    return x - y * floor(x / y);
}

// 2Dの回転処理
void rot(inout float2 p, float a)
{
    p = mul(p, float2x2(cos(a), sin(a), -sin(a), cos(a)));
}

// 六角形のタイルの距離関数
// https://www.shadertoy.com/view/Xd2GR3
// return { xy: セルID, z: 六角形のボーダーへの距離, w: 六角形の中心への距離 }
float4 hexagon(inout float2 p)
{
    float2 q = float2(p.x * 2.0 * 0.5773503, p.y + p.x * 0.5773503);
    float2 pi = floor(q);
    float2 pf = frac(q);

    float v = mod(pi.x + pi.y, 3.0);

    float ca = step(1.0, v);
    float cb = step(2.0, v);
    float2 ma = step(pf.xy, pf.yx);

    // 六角形のボーダーへの距離
    float e = dot(ma, 1.0 - pf.yx +
        ca * (pf.x + pf.y - 1.0) + cb * (pf.yx - 2.0 * pf.xy));

    // 六角形の中心への距離
    p = float2(q.x + floor(0.5 + p.y / 1.5), 4.0 * p.y / 3.0) * 0.5 + 0.5;
    p = (frac(p) - 0.5) * float2(1.0, 0.85);
    float f = length(p);

    return float4(pi + ca - cb * ma, e, f);
}

// 箱の距離関数
float sdBox(in float2 p, in float2 b)
{
    float2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// 警告タイルのパターンを計算します
float warning(float2 p)
{
    float4 h = hexagon(p);
    beatTau = beat * PI * 2;
    beatPhase = phase(beat / 4);

    // タイルの輝度はイージングされたランダムな値
    float f = frac(hash12(h.xy) + beatPhase);

    // タイルの輝度を周期的なタイミングで斜線のようにする
    f = lerp(f, saturate(sin(h.x - h.y + 4. * beatPhase)),
        .5 + .5 * sin(beatTau / 16.));

    float hex = smoothstep(0.10, 0.11, h.z) * f;  // 六角形のタイルのボーダー
    float mark = 1.;  // タイルの内側のアイコンのような模様（マーク）
    float dice = frac(hash12(h.xy) + beatPhase / 4.);  // 0-1の乱数

    if (dice < .5)
    {
        // 50%の確率で斜め線のようなマークにします
        // ◤◢◤◢◤◢◤◢
        float d = sdBox(p, float2(0.4, dice));
        float ph = phase(beat / 2. + f);
        float ss = smoothstep(1.0, 1.05, mod(p.x * 10. + 10. * p.y + 8. * ph, 2.));
        mark = saturate(step(0, d) + ss);
    }
    else
    {
        // 50%の確率でIFS（Iterated function system）によるマークにします
        // 乱数で8種類のIFSパラメーターのプリセットを出し分けします
        float4 param;
        int i = int(mod(dice * 33.01, 8));
        if (i == 0) param = float4(140, 72, 0, 0);
        else if (i == 1) param = float4(0, 184, 482, 0);
        else if (i == 2) param = float4(541, 156, 453, 0);
        else if (i == 3) param = float4(112, 0, 301, 0);
        else if (i == 4) param = float4(0, 0, 753, 0);
        else if (i == 5) param = float4(311, 172, 50, 0);
        else if (i == 6) param = float4(249, 40, 492, 0);
        else if (i == 7) param = float4(0, 0, 0, 0);
        param /= float2(1200, 675).xyxy;

        // IFSによって模様を計算します
        // forループの中で2D座標を折りたたみ・平行移動・回転をさせます
        // 折りたたみについては以下の記事を参考にしてください
        // 距離関数のfold（折りたたみ）による形状設計 | gam0022.net
        // https://gam0022.net/blog/2017/03/02/raymarching-fold/
        float2 p1 = p - param.xy;
        for (int j = 0; j < 3; j++)
        {
            p1 = abs(p1 + param.xy) - param.xy;  // 折りたたみと並行移動
            rot(p1, PI * 2 * param.z);  // 回転
        }

        float d = sdBox(p1, float2(0.2, 0.05));  // 箱の距離関数

        // 距離関数からグレースケールのシルエットに変換
        mark = saturate(smoothstep(0, 0.01, d));
    }

    return hex * mark;  // 六角形のタイルとマークを合成
}

// Custom Functionのインターフェイスとなる関数
// ・出力は返り値ではなくてoutの引数
// ・関数の末尾に精度を指定する _float のsuffixが必要
void Warning_float(float2 uv, out float Out)
{
    Out = warning(uv);
}

#endif  // PROCEDURAL_TEXTURE_INCLUDE