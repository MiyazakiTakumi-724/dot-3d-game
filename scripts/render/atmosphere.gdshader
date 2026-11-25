// 画面全体の明るさ（Atmosphere）。描いた世界にかけ算で重ねる。
// - 雲の影：ワールドに貼りついたゆっくり流れる雲の影（外の地方）
// - 暗さと明かり：溶岩・廃城・塔の地方は暗く、たき火・炎・溶岩・主人公のまわりだけ明るい
// - 画面のふちを少し暗くする
shader_type canvas_item;
render_mode blend_mul, unshaded;

uniform vec2 focus = vec2(0.0);
uniform float angle = 0.0;
uniform float time = 0.0;
uniform float clouds = 0.0;
uniform float ambient = 1.0;
uniform vec3 tint : source_color = vec3(1.0);
uniform vec3 light_color : source_color = vec3(1.0, 0.84, 0.6);
uniform int light_count = 0;
uniform vec4 lights[16];
uniform float vignette = 0.22;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec2 px = SCREEN_UV * vec2(320.0, 180.0);
	vec2 rel = px - vec2(160.0, 90.0);
	vec2 world = focus + vec2(rel.x * cos(angle) - rel.y * sin(angle), rel.x * sin(angle) + rel.y * cos(angle));
	float cloud = 1.0;
	if (clouds > 0.0) {
		vec2 w = world / 210.0 + vec2(time * 0.014, time * 0.005);
		float n = noise(w) * 0.62 + noise(w * 2.13 + vec2(3.7, 1.3)) * 0.28 + noise(w * 4.7 + vec2(9.1, 4.2)) * 0.1;
		cloud = 1.0 - clouds * smoothstep(0.4, 0.6, n);
	}
	vec3 col = tint * ambient;
	float lit = 0.0;
	for (int i = 0; i < 16; i++) {
		if (i >= light_count) {
			break;
		}
		vec4 l = lights[i];
		float d = distance(px, l.xy);
		lit += l.w * (1.0 - smoothstep(l.z * 0.2, l.z, d));
	}
	col = max(col, light_color * clamp(lit, 0.0, 1.0));
	float v = 1.0 - vignette * smoothstep(0.42, 0.95, length((SCREEN_UV - 0.5) * vec2(1.7, 1.0)));
	COLOR = vec4(col * cloud * v, 1.0);
}
