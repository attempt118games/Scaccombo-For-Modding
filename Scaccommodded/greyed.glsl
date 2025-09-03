vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 texColor = Texel(tex, texture_coords);
    
    // Invert all the RGB components
    texColor.rgb = texColor.rgb * 0.5;  // Inverts the color (photonegative effect)

    return texColor * color;  // Apply color transformation
}
