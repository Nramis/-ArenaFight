shader_type canvas_item;
render_mode unshaded;

uniform vec4 cloth_color : source_color = vec4(0.15, 0.65, 1.0, 1.0);
uniform float palette_strength : hint_range(0.0, 1.0) = 0.78;
varying vec4 vertex_tint;

void vertex() {
    vertex_tint = COLOR;
}

void fragment() {
    vec4 texel = texture(TEXTURE, UV);
    vec3 c = texel.rgb;
    float brightest = max(c.r, max(c.g, c.b));
    float darkest = min(c.r, min(c.g, c.b));
    float chroma = brightest - darkest;
    // Keep the warm facial/hand palette, hair, ink outlines and white highlights.
    float warm = step(c.b + 0.025, c.g) * step(c.g + 0.018, c.r);
    float skin = warm * smoothstep(0.20, 0.40, c.r) * (1.0 - smoothstep(0.34, 0.64, c.r - c.g));
    float ink = smoothstep(0.07, 0.21, brightest);
    float highlights = 1.0 - smoothstep(0.78, 0.98, darkest);
    float clothing = max(smoothstep(0.035, 0.20, chroma), (1.0 - smoothstep(0.03, 0.12, chroma)) * 0.70) * (1.0 - skin) * ink * highlights;
    float luminance = dot(c, vec3(0.299, 0.587, 0.114));
    vec3 palette = cloth_color.rgb * (0.28 + luminance * 1.12);
    palette += vec3(max(0.0, luminance - 0.66) * 0.42);
    COLOR = vec4(mix(c, palette, clothing * palette_strength), texel.a) * vertex_tint;
}
