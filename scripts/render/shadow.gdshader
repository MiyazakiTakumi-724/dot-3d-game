// 地面の柱の材質（ShadowMap）。ふだんは絵をそのまま描く。
// 色の a が 0.5 の四角（柱の上の面）だけは影の計算をする：色の r・g がマス、b が高さ。
// マスの中の点から日の方へたどり、高さの絵（height_tex）の物が影の線より高ければ、影の色を描く。
shader_type canvas_item;

uniform sampler2D height_tex : filter_nearest;
uniform vec2 area_cells = vec2(16.0, 16.0);
uniform vec2 sun = vec2(-0.94, 0.34);
uniform float cells_per_level = 0.55;
uniform float height_range = 16.0;
uniform vec4 shade_color : source_color = vec4(0.10, 0.07, 0.28, 0.42);

void fragment() {
	if (abs(COLOR.a - 0.5) < 0.02) {
		vec2 cell = floor(COLOR.rg * 255.0 + 0.5);
		float h = COLOR.b * height_range;
		// ゲームの座標の1px（1マス＝16）ごとにそろえて、ドット絵らしい影のふちにする
		vec2 p = cell + (floor(UV * 16.0) + 0.5) / 16.0;
		float shade = 0.0;
		for (int k = 1; k <= 28; k++) {
			float t = float(k) * 0.125;
			vec2 q = p + sun * t;
			if (q.x < 0.0 || q.y < 0.0 || q.x >= area_cells.x || q.y >= area_cells.y) {
				break;
			}
			float occ = texture(height_tex, q / area_cells).r * height_range;
			if (occ > h + t / cells_per_level + 0.05) {
				shade = 1.0;
				break;
			}
		}
		COLOR = vec4(shade_color.rgb, shade_color.a * shade);
	} else {
		COLOR = texture(TEXTURE, UV) * COLOR;
	}
}
