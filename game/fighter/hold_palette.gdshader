shader_type canvas_item;
render_mode unshaded;
uniform bool mavrin_enabled = false;
uniform bool polina_enabled = false;
uniform vec4 mavrin_color : source_color = vec4(1.0);
uniform vec4 polina_color : source_color = vec4(1.0);
varying vec4 vertex_tint;
void vertex() { vertex_tint = COLOR; }
void fragment() {
    vec4 pixel = texture(TEXTURE, UV);
    vec3 c = pixel.rgb;
    float bright = max(c.r, max(c.g, c.b));
    float dark = min(c.r, min(c.g, c.b));
    float yellow = step(c.b * 1.7, c.g) * step(c.r * 0.68, c.g) * smoothstep(0.12, 0.42, c.g);
    float neutral = (1.0 - smoothstep(0.05, 0.17, bright - dark)) * smoothstep(0.24, 0.6, bright);
    float light = dot(c, vec3(0.299, 0.587, 0.114));
    if (mavrin_enabled) c = mix(c, mavrin_color.rgb * (0.3 + light), yellow * 0.78);
    if (polina_enabled) c = mix(c, polina_color.rgb * (0.35 + light * .85), neutral * .55);
    COLOR = vec4(c, pixel.a) * vertex_tint;
}
