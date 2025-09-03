extern vec2 texSize;

vec4 effect(vec4 color, Image tex, vec2 texCoord, vec2 screenCoord)
{
    float dx = 1.0 / texSize.x;
    float dy = 1.0 / texSize.y;

    vec4 center = Texel(tex, texCoord);
    vec4 right  = Texel(tex, texCoord + vec2(dx, 0.0));
    vec4 down   = Texel(tex, texCoord + vec2(0.0, dy));

    // Detect edges based on RGB only (ignore alpha)
    float diffRight = length(center.rgb - right.rgb);
    float diffDown  = length(center.rgb - down.rgb);
    float edge = smoothstep(0.05, 0.2, max(diffRight, diffDown));

    // Blend only the color, preserve original alpha
    vec3 blended = mix(center.rgb, (center.rgb + right.rgb + down.rgb) / 3.0, edge);

    return vec4(blended, center.a) * color;
}
