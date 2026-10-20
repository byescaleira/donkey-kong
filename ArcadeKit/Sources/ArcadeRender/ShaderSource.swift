import Foundation

enum ShaderSource {
    static let metal = #"""
#include <metal_stdlib>
using namespace metal;

struct PostUniforms {
    float2 outputSize;
    float2 sourceSize;
    float scanlineStrength;
    float scanlineCount;
    float vignette;
    float aberration;
    float curvature;
    float bloom;
    float sharpen;
};

struct QuadVertex {
    float4 position [[position]];
    float2 uv;
};

vertex QuadVertex fullscreen_vertex(uint vertexID [[vertex_id]]) {
    const float2 corners[4] = {
        float2(-1.0, -1.0), float2(1.0, -1.0), float2(-1.0, 1.0), float2(1.0, 1.0)
    };
    float2 corner = corners[vertexID];
    QuadVertex out;
    out.position = float4(corner, 0.0, 1.0);
    out.uv = float2((corner.x + 1.0) * 0.5, 1.0 - (corner.y + 1.0) * 0.5);
    return out;
}

static float2 curve_uv(float2 uv, float amount) {
    float2 centered = uv * 2.0 - 1.0;
    float2 squared = centered.yx * centered.yx * amount;
    centered += centered * squared;
    return centered * 0.5 + 0.5;
}

static float3 sample_sharp(texture2d<float> source, sampler smp, float2 uv, float2 sourceSize,
                           float sharpen) {
    if (sharpen <= 0.001) {
        return source.sample(smp, uv).rgb;
    }
    float2 texel = uv * sourceSize;
    float2 center = floor(texel) + 0.5;
    float2 delta = clamp((texel - center) / sharpen, -0.5, 0.5);
    return source.sample(smp, (center + delta) / sourceSize).rgb;
}

fragment float4 crt_fragment(QuadVertex in [[stage_in]],
                             texture2d<float> source [[texture(0)]],
                             constant PostUniforms &settings [[buffer(0)]],
                             sampler smp [[sampler(0)]]) {
    float2 uv = settings.curvature > 0.0001 ? curve_uv(in.uv, settings.curvature) : in.uv;
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        return float4(0.0, 0.0, 0.0, 1.0);
    }

    float3 color;
    if (settings.aberration > 0.0001) {
        float2 direction = uv - 0.5;
        float3 shiftedRed =
            sample_sharp(source, smp, uv + direction * settings.aberration, settings.sourceSize,
                         settings.sharpen);
        float3 base = sample_sharp(source, smp, uv, settings.sourceSize, settings.sharpen);
        float3 shiftedBlue =
            sample_sharp(source, smp, uv - direction * settings.aberration, settings.sourceSize,
                         settings.sharpen);
        color = float3(shiftedRed.r, base.g, shiftedBlue.b);
    } else {
        color = sample_sharp(source, smp, uv, settings.sourceSize, settings.sharpen);
    }

    if (settings.bloom > 0.0001) {
        float2 step = 1.5 / max(settings.outputSize, float2(1.0));
        float3 blur = source.sample(smp, uv + float2(step.x, 0.0)).rgb;
        blur += source.sample(smp, uv - float2(step.x, 0.0)).rgb;
        blur += source.sample(smp, uv + float2(0.0, step.y)).rgb;
        blur += source.sample(smp, uv - float2(0.0, step.y)).rgb;
        blur *= 0.25;
        color += max(blur - 0.55, 0.0) * settings.bloom;
    }

    if (settings.scanlineStrength > 0.0001 && settings.scanlineCount > 1.0) {
        float phase = uv.y * settings.scanlineCount * 6.2831853;
        float mask = 1.0 - settings.scanlineStrength * (0.5 - 0.5 * cos(phase));
        color *= mask;
    }

    if (settings.vignette > 0.0001) {
        float2 offset = uv - 0.5;
        float falloff = 1.0 - settings.vignette * dot(offset, offset) * 2.4;
        color *= clamp(falloff, 0.0, 1.0);
    }

    return float4(color, 1.0);
}
"""#
}
