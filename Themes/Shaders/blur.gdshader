shader_type canvas_item;

uniform float lod: hint_range(0.0, 5.0) = 0.0;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;
uniform float darkness: hint_range(0.0, 1.0) = 0.3; // 0.0 = sem escurecer, 1.0 = totalmente preto

void fragment() {
	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV, lod);
	color.rgb *= (1.0 - darkness); // reduz o brilho do que está atrás
	COLOR = vec4(color.rgb, 1.0);
}
