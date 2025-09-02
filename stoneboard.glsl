extern number iTime;
extern vec3 baseColor; // white or black tile color

// --- Hash & noise
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i+vec2(1.0,0.0));
    float c = hash(i+vec2(0.0,1.0));
    float d = hash(i+vec2(1.0,1.0));
    vec2 u = f*f*(3.0-2.0*f);
    return mix(a,b,u.x) + (c-a)*u.y*(1.0-u.x) + (d-b)*u.x*u.y;
}

// --- Multi-octave noise
float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for(int i=0;i<5;i++) {
        v += a * noise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

vec4 effect(vec4 color, Image tex, vec2 texCoords, vec2 screen_coords) {
    vec2 uv = texCoords * 6.0; // detail scale

    // Base flat color
    vec3 col = baseColor;

    // Stone grain pattern (light + dark speckles)
    float grain = fbm(uv);
    vec3 grainCol = mix(vec3(0.85,0.85,0.85), vec3(0.2,0.2,0.2), grain);
    col = mix(col, grainCol, 0.25);  // blend 25% noise into tile

    // Subtle scratches (directional noise)
    float scratches = sin(uv.x*40.0 + fbm(uv*3.0)*10.0);
    scratches = smoothstep(0.7, 1.0, scratches);
    col = mix(col, col*0.7, scratches*0.3);

    // Edge wear — chips near tile borders
    float edge = min(min(texCoords.x, texCoords.y), min(1.0-texCoords.x, 1.0-texCoords.y));
    float wear = smoothstep(0.0, 0.1, edge);
    col = mix(vec3(0.15), col, wear);

    return vec4(col,1.0) * color;
}
