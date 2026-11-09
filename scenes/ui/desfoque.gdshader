shader_type canvas_item;
// Desfoque gaussiano (21x21 amostras) e escurecimento, para fundos atrás de UI.
uniform float passo = 2.0;
uniform float escurecer : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	vec3 soma = vec3(0.0);
	float pesos = 0.0;
	for (int x = -10; x <= 10; x++) {
		for (int y = -10; y <= 10; y++) {
			float peso = exp(-float(x * x + y * y) / 50.0);
			soma += texture(TEXTURE, UV + vec2(float(x), float(y)) * TEXTURE_PIXEL_SIZE * passo).rgb * peso;
			pesos += peso;
		}
	}
	COLOR = vec4(soma / pesos * (1.0 - escurecer), 1.0);
}
