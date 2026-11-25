// 光の輝き（Atmosphere の上にたす）。たき火・炎・溶岩・魔法の弾のまわりを、あたたかい色でほんのり明るくする。
// ドット絵らしく、明るさを10段にし、段の間は本当の画面の1pxごとの点々でつなぐ。
shader_type canvas_item;
render_mode blend_add, unshaded;

uniform int light_count = 0;
uniform vec4 lights[16];
uniform float glows[16];
uniform vec3 glow_color : source_color = vec3(1.0, 0.62, 0.28);
uniform float strength = 0.3;

float bayer2(vec2 a) {
	a = floor(a);
	return fract(dot(a, vec2(0.5, a.y * 0.75)));
}

float bayer4(vec2 a) {
	return bayer2(0.5 * a) * 0.25 + bayer2(a);
}

void fragment() {
	vec2 px = SCREEN_UV * vec2(320.0, 180.0);
	float g = 0.0;
	for (int i = 0; i < 16; i++) {
		if (i >= light_count) {
			break;
		}
		vec4 l = lights[i];
		float r = l.z * 0.6;
		float k = max(0.0, 1.0 - distance(px, l.xy) / r);
		g += glows[i] * l.w * k * k;
	}
	g = clamp(g, 0.0, 1.0) * strength;
	vec2 rp = floor(SCREEN_UV * vec2(640.0, 360.0));
	float q = floor(g * 10.0 + bayer4(rp)) / 10.0;
	COLOR = vec4(glow_color * q, 1.0);
}
