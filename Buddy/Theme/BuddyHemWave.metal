#include <metal_stdlib>
using namespace metal;

/// Distorts only the lower hem — cloth wave L↔R. Body above ~72% stays put.
[[ stitchable ]] float2 buddyHemWave(float2 position, float time, float size, float amp) {
    float hemStart = size * 0.72;
    float falloff = smoothstep(hemStart, size, position.y);
    falloff *= falloff; // strongest at scallop tips

    // ~2.5 scallop cycles across the ghost width
    float freq = (6.28318530718 * 2.5) / max(size, 1.0);
    // Phase ping-pongs so the wave travels L→R then R→L
    float travel = sin(time * 2.2) * 3.14159265;
    float phase = position.x * freq + travel;

    // Vertical flutter of the hem edge (the “waving sheet”)
    float dy = sin(phase) * amp * falloff;
    // Light horizontal weave so it reads as fabric, not a bounce
    float dx = cos(phase * 0.85 + 0.6) * amp * 0.35 * falloff;

    return position + float2(dx, dy);
}
