// 地面の柱の材質（ShadowMap）。ふだんは絵をそのまま描く。
// 色の a が 0.5 の四角（柱の上の面）だけは、地面の模様と影を描く：色の r・g がマス、b が高さ。
// 2026-11-26（4回目の直し）：添付の映像のように、地面に細かい模様を足す。
// - 草：大きなまだらと、細かい草の葉（本当の画面の1pxごと）
// - 土の道（ふちはぎざぎざ）・山の小石・雪のきらめき・黒い土の光る割れ目・石畳（大きさの違う石と、光の当たるふち）
// - 水：さざ波・きらめき・岸の白い泡。溶岩：流れる明るい所と、冷えて黒い所
// - 高い所のそばの、地面の暗がり（かげり）
// - 影：日の方へたどって、物が影の線より高ければ影。日の向きと影の長さを1pxごとに少しずらし、影のふちを点々にする
// 草の葉（線）は頂点の色の a で目印を付け、先の点だけ風でゆらす（a 0.75 = 先、0.70 = 根もと）。
shader_type canvas_item;

uniform sampler2D height_tex : filter_nearest;
uniform vec2 area_cells = vec2(16.0, 16.0);
uniform vec2 sun = vec2(-0.94, 0.34);
uniform float cells_per_level = 0.55;
uniform float height_range = 16.0;
uniform vec4 shade_color : source_color = vec4(0.10, 0.07, 0.28, 0.42);
uniform int res = 8;
uniform float cam_angle = 0.0;

const int S_GRASS = 1;
const int S_ALPINE = 2;
const int S_SNOW = 3;
const int S_ASH = 4;
const int S_STONE = 5;
const int S_WATER = 7;
const int S_LAVA = 8;
const int F_PATH = 1;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float bayer2(vec2 a) {
	a = floor(a);
	return fract(dot(a, vec2(0.5, a.y * 0.75)));
}

// 0〜1 のしきい値（4×4 の並び）。点々にするのに使う
float bayer4(vec2 a) {
	return bayer2(0.5 * a) * 0.25 + bayer2(a) + 0.03;
}

// top を base の上に重ねる（a は不透明さ）
vec4 over(vec4 base, vec4 top) {
	float a = top.a + base.a * (1.0 - top.a);
	if (a <= 0.0) {
		return vec4(0.0);
	}
	return vec4((top.rgb * top.a + base.rgb * base.a * (1.0 - top.a)) / a, a);
}

vec4 cell_info(vec2 cell) {
	ivec2 c = clamp(ivec2(cell), ivec2(0), ivec2(area_cells) - 1);
	return texelFetch(height_tex, c * res + res / 2, 0);
}

int surf_of(vec4 info) {
	return int(info.g * 255.0 + 0.5);
}

int flags_of(vec4 info) {
	return int(info.b * 255.0 + 0.5);
}

bool outside(vec2 cell) {
	return cell.x < 0.0 || cell.y < 0.0 || cell.x >= area_cells.x || cell.y >= area_cells.y;
}

// 草の模様（下の絵に重ねる、うすい明暗）。density は草の葉の多さ
vec4 grass_detail(vec2 wp, float density) {
	vec4 d = vec4(0.0);
	float big = vnoise(wp / 52.0) * 0.6 + vnoise(wp / 19.0 + vec2(4.1, 7.3)) * 0.4;
	if (big < 0.46) {
		d = vec4(0.03, 0.17, 0.07, min(0.24, (0.46 - big) * 0.9));
	} else if (big > 0.58) {
		d = vec4(0.93, 1.0, 0.62, min(0.14, (big - 0.58) * 0.6));
	}
	// 草の葉：縦に短い線（根もとが暗く、先が明るい）
	float off = floor(hash(vec2(wp.x, 7.0)) * 5.0);
	float j = floor((wp.y + off) / 5.0);
	float r = hash(vec2(wp.x, j));
	if (r < density) {
		float yy = mod(wp.y + off, 5.0);
		if (yy > 3.5) {
			d = over(d, vec4(0.02, 0.13, 0.05, 0.34));
		} else if (yy > 2.5) {
			d = over(d, vec4(0.04, 0.18, 0.06, 0.18));
		} else if (yy < 0.5) {
			d = over(d, vec4(0.92, 1.0, 0.58, 0.2));
		}
	}
	// ななめの葉（ところどころ）
	float r2 = hash(vec2(floor((wp.x + wp.y) / 2.0), floor(wp.y / 3.0)) + vec2(13.0, 3.0));
	if (r2 > 0.93) {
		d = over(d, vec4(0.03, 0.15, 0.05, 0.22));
	}
	if (hash(wp + vec2(31.0, 17.0)) > 0.993) {
		d = over(d, vec4(1.0, 1.0, 0.78, 0.4));
	}
	return d;
}

// 石畳：マスごとに、大きな石1つ・中くらい4つ・その1つをさらに小さく4つ。光は西南西から
vec4 tile_detail(vec2 local, vec2 cell, vec2 wp) {
	float size = 32.0;
	vec2 org = vec2(0.0);
	if (hash(cell + vec2(3.0, 7.0)) > 0.35) {
		size = 16.0;
		org = floor(local / 16.0) * 16.0;
		if (hash(cell * 2.0 + floor(local / 16.0) + vec2(1.0, 2.0)) > 0.72) {
			size = 8.0;
			org = floor(local / 8.0) * 8.0;
		}
	}
	vec2 t = local - org;
	float tone = hash(cell * 4.0 + org + vec2(0.3, 0.7));
	vec4 d = tone > 0.5 ? vec4(1.0, 0.98, 0.92, (tone - 0.5) * 0.14) : vec4(0.0, 0.0, 0.04, (0.5 - tone) * 0.2);
	if (t.x < 0.5 || t.y < 0.5) {
		d = over(d, vec4(0.05, 0.04, 0.07, 0.55));
	} else if (t.x < 1.5 || t.y > size - 1.5) {
		d = over(d, vec4(1.0, 0.97, 0.88, 0.2));
	} else if (t.x > size - 1.5 || t.y < 1.5) {
		d = over(d, vec4(0.0, 0.0, 0.06, 0.26));
	} else if (hash(wp + vec2(9.0, 3.0)) > 0.955) {
		d = over(d, vec4(0.0, 0.0, 0.0, 0.16));
	} else if (hash(wp + vec2(2.0, 5.0)) > 0.985) {
		d = over(d, vec4(1.0, 1.0, 1.0, 0.18));
	}
	// ひび（ときどき）
	if (size > 8.0 && hash(cell + org + vec2(11.0, 5.0)) > 0.8) {
		float line = abs(t.y - (size * 0.3 + t.x * 0.5 + 2.0 * sin(t.x * 0.7)));
		if (line < 0.6 && t.x > 2.0 && t.x < size - 4.0) {
			d = over(d, vec4(0.04, 0.03, 0.05, 0.4));
		}
	}
	return d;
}

// 土の道（不透明）。ふちは隣の道でないマスの方からぎざぎざに削る（削った所は草のまま：a 0）
vec4 path_detail(vec2 wp, vec2 local, vec2 cell, int surf) {
	float edge = 99.0;
	float along = 0.0;
	vec2 dirs[4] = vec2[](vec2(0.0, -1.0), vec2(1.0, 0.0), vec2(0.0, 1.0), vec2(-1.0, 0.0));
	for (int i = 0; i < 4; i++) {
		vec2 n = cell + dirs[i];
		if (outside(n)) {
			continue;
		}
		if ((flags_of(cell_info(n)) & F_PATH) != 0) {
			continue;
		}
		float dist = i == 0 ? local.y : (i == 1 ? 31.0 - local.x : (i == 2 ? 31.0 - local.y : local.x));
		float a = (i == 0 || i == 2) ? wp.x : wp.y;
		float w = 4.0 + floor(vnoise(vec2(a / 3.0, float(i) * 7.0 + cell.x + cell.y)) * 6.0);
		if (dist - w < edge) {
			edge = dist - w;
			along = a;
		}
	}
	if (edge < 0.0) {
		return vec4(0.0);
	}
	vec3 base = vec3(0.71, 0.52, 0.32);
	if (surf == S_ALPINE) {
		base = vec3(0.6, 0.55, 0.47);
	} else if (surf == S_SNOW) {
		base = vec3(0.77, 0.8, 0.88);
	} else if (surf == S_ASH) {
		base = vec3(0.24, 0.2, 0.21);
	}
	vec3 c = base * (0.93 + 0.14 * vnoise(wp / 21.0));
	float n = hash(floor(wp / 2.0));
	if (n < 0.2) {
		c *= 0.8;
	} else if (n > 0.9) {
		c *= 1.12;
	}
	if (hash(floor(wp / 2.0) + vec2(5.0, 9.0)) > 0.976) {
		c = surf == S_ASH ? vec3(0.45, 0.4, 0.4) : vec3(0.63, 0.6, 0.56);
	}
	if (edge < 1.0) {
		c = base * 0.62;  // ふちの暗い線
	}
	return vec4(c, 1.0);
}

vec4 water_detail(vec2 wp, vec2 local, vec2 cell) {
	float t = TIME;
	vec4 d = vec4(0.0);
	float deep = vnoise(wp / 56.0 + vec2(t * 0.02, 0.0));
	d = deep > 0.5 ? vec4(0.85, 1.0, 1.0, (deep - 0.5) * 0.24) : vec4(0.1, 0.42, 0.62, (0.5 - deep) * 0.2);
	float wave = sin(wp.y * 0.32 + vnoise(wp / 24.0 + vec2(t * 0.12, t * 0.05)) * 7.0 + t * 1.3);
	if (wave > 0.9) {
		d = over(d, vec4(0.88, 1.0, 1.0, 0.32));
	}
	if (hash(floor(wp / 2.0) + floor(t * 3.0) * vec2(0.37, 0.71)) > 0.988) {
		d = over(d, vec4(1.0, 1.0, 1.0, 0.85));
	}
	// 岸の白い泡
	vec2 dirs[4] = vec2[](vec2(0.0, -1.0), vec2(1.0, 0.0), vec2(0.0, 1.0), vec2(-1.0, 0.0));
	for (int i = 0; i < 4; i++) {
		vec2 n = cell + dirs[i];
		if (outside(n) || surf_of(cell_info(n)) == S_WATER) {
			continue;
		}
		float dist = i == 0 ? local.y : (i == 1 ? 31.0 - local.x : (i == 2 ? 31.0 - local.y : local.x));
		float a = (i == 0 || i == 2) ? wp.x : wp.y;
		float foam = 1.5 + 1.5 * sin(a * 0.4 + t * 2.0 + float(i));
		if (dist < foam) {
			d = over(d, vec4(0.92, 1.0, 1.0, 0.6));
		} else if (dist < foam + 2.0 && hash(vec2(a, floor(t * 2.0))) > 0.6) {
			d = over(d, vec4(0.92, 1.0, 1.0, 0.3));
		}
	}
	return d;
}

vec4 lava_detail(vec2 wp) {
	float t = TIME;
	float n = vnoise(wp / 13.0 + vec2(t * 0.16, t * 0.06)) * 0.7 + vnoise(wp / 5.0 - vec2(t * 0.1, 0.0)) * 0.3;
	vec4 d = vec4(1.0, 0.86, 0.32, smoothstep(0.55, 0.85, n) * 0.75);
	float crust = vnoise(wp / 9.0 - vec2(t * 0.03, t * 0.02));
	if (crust > 0.72) {
		d = over(d, vec4(0.22, 0.07, 0.05, min(0.7, (crust - 0.72) * 5.0)));
	}
	if (hash(floor(wp / 3.0) + floor(t * 1.5) * vec2(0.3, 0.9)) > 0.993) {
		d = over(d, vec4(1.0, 0.97, 0.7, 0.9));
	}
	return d;
}

vec4 surface_detail(int surf, int flags, vec2 cell, vec2 local, vec2 wp) {
	vec4 d = vec4(0.0);
	if (surf == S_GRASS) {
		d = grass_detail(wp, 0.42);
	} else if (surf == S_ALPINE) {
		d = grass_detail(wp, 0.26);
		if (hash(floor(wp / 2.0) + vec2(7.0, 1.0)) > 0.985) {
			d = over(d, vec4(0.56, 0.56, 0.6, 0.9));
		}
	} else if (surf == S_SNOW) {
		float n = vnoise(wp / 30.0);
		d = vec4(0.55, 0.66, 0.95, n * 0.16);
		float s = hash(wp + vec2(4.0, 2.0));
		if (s > 0.992 && sin(TIME * 3.0 + s * 900.0) > 0.3) {
			d = over(d, vec4(1.0, 1.0, 1.0, 0.95));
		}
	} else if (surf == S_ASH) {
		float n = hash(floor(wp / 2.0));
		if (n < 0.25) {
			d = vec4(0.06, 0.04, 0.05, 0.32);
		} else if (n > 0.92) {
			d = vec4(0.75, 0.7, 0.7, 0.14);
		}
		float c = abs(vnoise(wp / 15.0 + vec2(cell.x * 0.0, 3.0)) - 0.5);
		if (c < 0.022) {
			d = over(d, vec4(1.0, 0.42 + 0.2 * sin(TIME * 2.0 + wp.x * 0.05), 0.12, 0.62));
		}
	} else if (surf == S_STONE) {
		d = tile_detail(local, cell, wp);
	} else if (surf == S_WATER) {
		d = water_detail(wp, local, cell);
	} else if (surf == S_LAVA) {
		d = lava_detail(wp);
	}
	if ((flags & F_PATH) != 0 && surf != S_WATER && surf != S_LAVA && surf != S_STONE) {
		vec4 p = path_detail(wp, local, cell, surf);
		if (p.a > 0.0) {
			d = p;
		}
	}
	return d;
}

// 高い所のそばの暗がり（4方向）
float occlusion(vec2 cell, vec2 local, float ground) {
	float ao = 0.0;
	vec2 dirs[4] = vec2[](vec2(0.0, -1.0), vec2(1.0, 0.0), vec2(0.0, 1.0), vec2(-1.0, 0.0));
	for (int i = 0; i < 4; i++) {
		vec2 n = cell + dirs[i];
		if (outside(n)) {
			continue;
		}
		float nh = cell_info(n).a * height_range;
		if (nh < ground + 0.6) {
			continue;
		}
		float dist = i == 0 ? local.y : (i == 1 ? 31.0 - local.x : (i == 2 ? 31.0 - local.y : local.x));
		ao = max(ao, 1.0 - dist / 6.0);
	}
	return ao;
}

void vertex() {
	bool tip = abs(COLOR.a - 0.75) < 0.015;
	if (tip || abs(COLOR.a - 0.7) < 0.015) {
		// 草の葉：VERTEX は根もとのワールドのずれ、UV は画面でのずれ（上の面の高さを含む）
		float c = cos(-cam_angle);
		float s = sin(-cam_angle);
		vec2 b = vec2(VERTEX.x * c - VERTEX.y * s, VERTEX.x * s + VERTEX.y * c);
		b = floor(b * 2.0 + 0.5) / 2.0 + vec2(0.25);
		VERTEX = b + UV;
		if (tip) {
			vec2 w = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
			VERTEX.x += sin(TIME * 2.3 + w.x * 0.11 + w.y * 0.04) * 0.35 + sin(TIME * 0.8 + w.x * 0.023) * 0.3;
		}
		COLOR.a = 1.0;
		UV = vec2(0.5);
	}
}

void fragment() {
	if (abs(COLOR.a - 0.5) < 0.02) {
		vec2 cell = floor(COLOR.rg * 255.0 + 0.5);
		float h = COLOR.b * height_range;
		vec2 local = clamp(floor(UV * 32.0), vec2(0.0), vec2(31.0));
		vec2 wp = cell * 32.0 + local;
		vec2 p = (wp + 0.5) / 32.0;
		vec4 info = cell_info(cell);
		int surf = surf_of(info);
		vec4 d = surface_detail(surf, flags_of(info), cell, local, wp);
		float bay = bayer4(wp);
		if (surf != S_WATER && surf != S_LAVA) {
			float ao = occlusion(cell, local, info.a * height_range);
			if (ao > bay) {
				d = over(d, vec4(0.06, 0.04, 0.16, 0.2));
			}
		}
		float shade = 0.0;
		if (surf != S_LAVA) {
			// 日の向きと影の長さを、1pxごとに少しずらす（影のふちが点々になる）
			float ang = (bay - 0.5) * 0.26;
			vec2 sd = vec2(sun.x * cos(ang) - sun.y * sin(ang), sun.x * sin(ang) + sun.y * cos(ang));
			float cpl = cells_per_level * (1.0 + (bayer4(wp + vec2(2.0, 1.0)) - 0.5) * 0.3);
			for (int k = 1; k <= 28; k++) {
				float t = float(k) * 0.125;
				vec2 q = p + sd * t;
				if (q.x < 0.0 || q.y < 0.0 || q.x >= area_cells.x || q.y >= area_cells.y) {
					break;
				}
				float occ = texture(height_tex, q / area_cells).r * height_range;
				if (occ > h + t / cpl + 0.05) {
					shade = 1.0;
					break;
				}
			}
		}
		COLOR = over(d, vec4(shade_color.rgb, shade_color.a * shade));
	} else {
		COLOR = texture(TEXTURE, UV) * COLOR;
	}
}
