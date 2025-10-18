shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(1.0);
uniform float softness : hint_range(0.0, 0.5) = 0.1;

void fragment() {
    // Distância até as bordas do retângulo
    float left = UV.x;
    float right = 1.0 - UV.x;
    float top = UV.y;
    float bottom = 1.0 - UV.y;

    // Menor distância até qualquer borda
    float edge_dist = min(min(left, right), min(top, bottom));

    // Cria o gradiente de alpha: 0 → bordas, 1 → centro
    float fade = smoothstep(0.0, softness, edge_dist);

    // Cor final com alpha suavizado nas bordas
    COLOR = base_color;
    COLOR.a *= fade;
}
