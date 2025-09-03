// Balatro-inspired vortex shader
// Adjusted colors to fit chessboard palette but still vibrant

#define SPIN_ROTATION -2
#define SPIN_SPEED 2.2
#define OFFSET vec2(0.0)
#define COLOUR_1 vec4(0.01, 0.01, 0.01, 1.0)   // warm sunset orange
#define COLOUR_2 vec4(0.48, 0.48, 0.48, 1.0)    // teal / turquoise
#define COLOUR_3 vec4(0.18, 0.18, 0.18, 1.0)   // muted violet-gray
#define CONTRAST 3.0
#define SPIN_AMOUNT 0.28
#define PIXEL_FILTER 520
#define SPIN_EASE 1.2
#define PI 3.14159265359

extern number iTime;
extern vec2 iResolution;

vec4 paintEffect(vec2 screenSize, vec2 screen_coords) {
    float pixel_size = length(screenSize.xy) / PIXEL_FILTER;
    vec2 uv = (floor(screen_coords.xy*(1./pixel_size))*pixel_size - 0.5*screenSize.xy)/length(screenSize.xy) - OFFSET;
    float uv_len = length(uv);

    // vortex swirl
    float speed = (SPIN_ROTATION*SPIN_EASE*0.25) + 300.0;
    float new_pixel_angle = atan(uv.y, uv.x) 
                          + speed 
                          - SPIN_EASE*18.0*(SPIN_AMOUNT*uv_len + (1. - SPIN_AMOUNT));
    vec2 mid = (screenSize.xy/length(screenSize.xy))/2.;
    uv = (vec2((uv_len * cos(new_pixel_angle) + mid.x), 
               (uv_len * sin(new_pixel_angle) + mid.y)) - mid);

    uv *= 28.0;
    speed = iTime*(SPIN_SPEED);
    vec2 uv2 = vec2(uv.x+uv.y);

    for(int i=0; i < 6; i++) {
        uv2 += sin(max(uv.x, uv.y)) + uv;
        uv  += 0.55*vec2(cos(5.1123314 + 0.353*uv2.y + speed*0.15),
                         sin(uv2.x - 0.11*speed));
        uv  -= 0.9*cos(uv.x + uv.y) - 0.9*sin(uv.x*0.71 - uv.y);
    }

    float contrast_mod = (0.3*CONTRAST + 0.45*SPIN_AMOUNT + 1.2);
    float paint_res = min(2., max(0.,length(uv)*(0.032)*contrast_mod));
    float c1p = max(0.,1. - contrast_mod*abs(1.-paint_res));
    float c2p = max(0.,1. - contrast_mod*abs(paint_res));
    float c3p = 1. - min(1., c1p + c2p);

    return (0.25/CONTRAST)*COLOUR_1 
         + (1. - 0.25/CONTRAST) * (
             COLOUR_1*c1p 
           + COLOUR_2*c2p 
           + vec4(c3p*COLOUR_3.rgb, 1.0));
}

vec4 effect(vec4 color, Image texture, vec2 texCoords, vec2 screen_coords) {
    vec2 fragCoord = screen_coords;
    vec2 uv = fragCoord / iResolution;
    return paintEffect(iResolution, uv * iResolution);
}
