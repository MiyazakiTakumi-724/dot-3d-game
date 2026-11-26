// 光の輝き（Atmosphere の上にたす）。たき火・炎・溶岩・魔法の弾のまわりを、あたたかい色でほんのり明るくする。
// ドット絵らしく、明るさを10段にし、段の間は本当の画面の1pxごとの点々でつなぐ。
shader_type canvas_item;
render_mode blend_add, unshaded;

uniform int light_count = 0;
uniform vec4 lights[16];
uniform float glows[16];
uniform vec3 glow_color : source_color = vec3(1.0, 0.62, 0.28);
uniform float strength = 0.3;
// 霧（2026-11-26、霧の谷）：ワールドに貼りついてゆっくり流れる白いもや。fog が0なら何もしない
uniform float fog = 0.0;
uniform vec3 fog_color : source_color = vec3(0.62, 0.68, 0.74);
uniform vec2 focus = vec2(0.0);
uniform float angle = 0.0;
uniform float time = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

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
	vec3 col = glow_color * q;
	if (fog > 0.0) {
		vec2 rel = px - vec2(160.0, 90.0);
		vec2 world = focus + vec2(rel.x * cos(angle) - rel.y * sin(angle), rel.x * sin(angle) + rel.y * cos(angle));
		vec2 w = world / 120.0 + vec2(time * 0.03, time * 0.008);
		float n = noise(w) * 0.6 + noise(w * 2.3 + vec2(4.1, 2.7)) * 0.3 + noise(w * 5.1) * 0.1;
		float f = fog * (0.45 + 0.75 * smoothstep(0.35, 0.75, n));
		float fq = floor(f * 12.0 + bayer4(rp)) / 12.0;
		col += fog_color * fq;
	}
	COLOR = vec4(col, 1.0);
}
