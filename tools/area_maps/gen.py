# 大陸の30エリアの地図を作り、scripts/areas/*.gd に書き出す。
# 使い方: python3 gen.py [--preview]   （--preview で preview_<id>.png も作る。Pillow が要る）
# 並べ方と中身は docs/superpowers/specs/2026-11-25-full-game-design.md（2026-11-25：野営地を町にし、エリアをせまくし、
# すべてのエリアに敵を置いた）。
#
# 地形の作り方
# 1. ノイズで高さを作る（エリアごとの傾きと、細かい段差）。隣との差は1段までにならす。
# 2. 崖のある高台を足す（ここだけ2段以上の差になる）。登り道（1段ずつの階段）をつける。
# 3. 仕掛け（寄り道）・たき火・商人・ボスの居場所を先に置き、地方の飾りを散らす。
# 4. 敵を置く（段差を登らない敵には4×4の平地を作る）。拾いものをばらまく。
# 5. 行かなければならない所（出口・拾いもの・敵）がつながっているか確かめ、
#    落ちたら戻れないくぼみは茂みでふさぐ。
import math, os, random, sys
from collections import deque
import heapq

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'scripts', 'areas')
WALLS = set('TPBRWIHOMKQXYVENJZk')  # 通れない物（X・Y・V・E・N は仕掛けで、開けるまで通れない。J レバー・Z 水晶。k 枯れ木は 2026-11-26）
BLOCK = WALLS | set('~_L')    # 通れないマス（水・奈落・溶岩を含む）
CLIMB, DROP = 1, 3
SPEED_CELLS = 60.0 / 16.0    # プレイヤーの速さ（マス/秒）

# ---------------------------------------------------------------- 大陸の上の置き方
# エリア：id → 名前・地方の見た目（theme）・大陸の上の左上のマス・大きさ。
# 真ん中に「はじまりの地」（町・岩場・丘陵・奥の森）。町の西に岩場、東に丘陵、北に奥の森。
# 岩場の西に山岳、丘陵の東に草原、奥の森の北に廃城、町の南に溶岩と神秘の塔（封印の門）。
# 地方は 入口 → 休憩所（たき火）→ 奥1 → 奥2（休憩所と奥1の両方に接する。休憩所への近道の門）→ ボスの間。
def A(title, theme, origin, size):
    return dict(title=title, theme=theme, origin=origin, size=size)

AREAS = {
    'town':   A('はじまりの町', 'town', (0, 0), (24, 20)),
    'rocks':  A('岩場', 'grass', (-22, 2), (22, 18)),
    'hills':  A('丘陵', 'grass', (24, -8), (24, 26)),
    'forest': A('奥の森', 'grass', (0, -18), (24, 18)),
    'mt_1': A('山すそ', 'mountain', (-44, 4), (22, 16)),
    'mt_2': A('山小屋', 'mountain', (-40, -12), (16, 16)),
    'mt_3': A('岩の尾根', 'mountain', (-56, -12), (16, 16)),
    'mt_4': A('雪の峠', 'mountain', (-56, -26), (32, 14)),
    'mt_5': A('巨人の岩棚', 'mountain', (-52, -46), (24, 20)),
    'mt_x': A('岩窟', 'mountain', (-74, -12), (18, 14)),
    'gr_1': A('草原の入口', 'grass', (48, 0), (22, 16)),
    'gr_2': A('風見の休み場', 'grass', (70, 0), (16, 16)),
    'gr_3': A('花の丘', 'grass', (70, -16), (16, 16)),
    'gr_4': A('背高草の野', 'grass', (86, -16), (14, 32)),
    'gr_5': A('大蛇の草むら', 'grass', (100, -10), (24, 20)),
    'cs_1': A('城下の跡', 'castle', (0, -34), (22, 16)),
    'cs_2': A('崩れた兵舎', 'castle', (2, -50), (16, 16)),
    'cs_3': A('城壁の道', 'castle', (-14, -50), (16, 16)),
    'cs_4': A('城の中庭', 'castle', (-14, -64), (32, 14)),
    'cs_5': A('王の間', 'castle', (-10, -84), (24, 20)),
    'lv_1': A('灰の道', 'lava', (6, 20), (18, 16)),
    'lv_2': A('湯けむりの休み場', 'lava', (6, 36), (16, 16)),
    'lv_3': A('溶岩の川', 'lava', (22, 36), (16, 16)),
    'lv_4': A('火口のふち', 'lava', (6, 52), (32, 14)),
    'lv_5': A('満ち引きのくぼ地', 'lava', (10, 66), (24, 20)),
    'lv_x': A('溶岩洞', 'lava', (-12, 52), (18, 14)),
    'tw_1': A('塔のふもと', 'tower', (-14, 20), (20, 18)),
    'tw_2': A('塔の中', 'tower', (-34, 20), (20, 18)),
    'tw_3': A('塔の外周', 'tower', (-34, 38), (20, 18)),
    'tw_4': A('塔の最上階', 'tower', (-34, 56), (20, 16)),
    # 寄り道のエリア（2026-11-25 夜）。地方ごとに3つ、どれにも「地方の印」が1つある。印を3つ持つとボスの間の門が開く。
    # 草原と廃城の隠しボスのエリアも足した（各地方に隠しボス1体）。
    'mt_6': A('凍った湖', 'mountain', (-66, 4), (22, 16)),
    'mt_7': A('鷹の巣', 'mountain', (-24, -26), (16, 14)),
    'mt_8': A('吹雪の谷', 'mountain', (-74, -26), (18, 14)),
    'gr_6': A('沼の小道', 'grass', (48, 16), (22, 14)),
    'gr_7': A('風車の跡', 'grass', (70, 16), (16, 14)),
    'gr_8': A('果ての草原', 'grass', (70, -32), (30, 16)),
    'gr_x': A('女王の巣', 'grass', (50, -32), (20, 16)),
    'cs_6': A('古い墓地', 'castle', (22, -34), (18, 16)),
    'cs_7': A('見張りの塔', 'castle', (18, -50), (16, 16)),
    'cs_8': A('地下牢', 'castle', (-30, -64), (16, 14)),
    'cs_x': A('宝物庫', 'castle', (-48, -64), (18, 14)),
    'lv_6': A('黒い森', 'lava', (24, 20), (16, 16)),
    'lv_7': A('硫黄の谷', 'lava', (38, 36), (16, 16)),
    'lv_8': A('灰の丘', 'lava', (38, 52), (16, 14)),
    'tw_5': A('塔の回廊', 'tower', (-14, 38), (18, 14)),
    # 霧の谷（2026-11-26 の4回目の直し）。草原の沼の小道の南。主人公の村の跡（灯りの村跡）と、闇の王の砦。
    # 霧の門は地方のぬしを2体倒すと開く。砦の門は村の跡の「村のお守り」で開く。
    'mv_1': A('霧の入口', 'mist', (54, 30), (22, 16)),
    'mv_2': A('灯りの村跡', 'mist', (56, 46), (16, 16)),
    'mv_3': A('霧の森', 'mist', (72, 46), (16, 16)),
    'mv_4': A('沈んだ街道', 'mist', (56, 62), (32, 14)),
    'mv_5': A('闇の砦', 'mist', (64, 76), (24, 20)),
    'mv_6': A('霧の湖', 'mist', (76, 30), (16, 16)),
}
REGION = {}
for k in AREAS:
    REGION[k] = {'mt': '山岳', 'gr': '草原', 'cs': '廃城', 'lv': '溶岩', 'tw': '神秘の塔', 'mv': '霧の谷'}.get(k[:2], 'はじまりの地')
# 地方ごとの敵の基本のレベル（scripts/rules/loot.gd の REGION_LEVEL と同じ）
REGION_LEVEL = {'はじまりの地': 1, '山岳': 2, '草原': 2, '廃城': 3, '溶岩': 3, '神秘の塔': 5, '霧の谷': 4}

# つながり：(エリアa, エリアb, 大陸の上のマスの範囲 g0〜g1, 門の id, 門を開けられる側)。
# 2つのエリアは辺を接していて、範囲はその辺に沿った大陸の座標（東西の辺なら y、南北の辺なら x）。
LINKS = [
    ('town', 'rocks', 9, 11, '', None),
    ('town', 'hills', 9, 11, '', None),
    ('forest', 'hills', -6, -4, '', None),
    ('town', 'forest', 10, 12, 'forest_gate', 'forest'),
    ('town', 'lv_1', 14, 16, '', None),
    ('town', 'tw_1', 2, 4, 'tower_seal', 'town'),   # 神秘の塔の封印の門（4つの地方のボスを倒すと町の側から開けられる）
    # 山岳
    ('rocks', 'mt_1', 11, 13, '', None),
    ('mt_1', 'mt_2', -32, -30, '', None),
    ('mt_2', 'mt_3', -6, -4, '', None),
    ('mt_3', 'mt_4', -50, -48, '', None),
    ('mt_4', 'mt_2', -30, -28, 'mt_gate', 'mt_4'),
    ('mt_4', 'mt_5', -42, -39, 'mt_boss', 'mt_4'),   # ボスの間の門（山岳の印を3つ持つと開く）
    ('mt_1', 'mt_6', 12, 14, '', None),
    ('mt_4', 'mt_7', -16, -14, '', None),
    ('mt_4', 'mt_8', -22, -20, '', None),
    ('mt_3', 'mt_x', -4, -2, '', None),
    # 草原
    ('hills', 'gr_1', 6, 8, '', None),
    ('gr_1', 'gr_2', 6, 8, '', None),
    ('gr_2', 'gr_3', 76, 78, '', None),
    ('gr_3', 'gr_4', -10, -8, '', None),
    ('gr_4', 'gr_2', 8, 10, 'gr_gate', 'gr_4'),
    ('gr_4', 'gr_5', -2, 1, 'gr_boss', 'gr_4'),
    ('gr_1', 'gr_6', 58, 60, '', None),
    ('gr_6', 'gr_7', 22, 24, '', None),
    ('gr_2', 'gr_7', 78, 80, '', None),
    ('gr_3', 'gr_8', 78, 80, '', None),
    ('gr_4', 'gr_8', 92, 94, '', None),
    ('gr_8', 'gr_x', -26, -24, '', None),
    # 廃城
    ('forest', 'cs_1', 10, 12, '', None),
    ('cs_1', 'cs_2', 8, 10, '', None),
    ('cs_2', 'cs_3', -44, -42, '', None),
    ('cs_3', 'cs_4', -8, -6, '', None),
    ('cs_4', 'cs_2', 10, 12, 'cs_gate', 'cs_4'),
    ('cs_4', 'cs_5', 1, 4, 'cs_boss', 'cs_4'),
    ('cs_1', 'cs_6', -22, -20, '', None),
    ('cs_6', 'cs_7', 26, 28, '', None),
    ('cs_2', 'cs_7', -40, -38, '', None),
    ('cs_4', 'cs_8', -60, -58, '', None),
    ('cs_8', 'cs_x', -58, -56, '', None),
    # 溶岩
    ('lv_1', 'lv_2', 12, 14, '', None),
    ('lv_2', 'lv_3', 42, 44, '', None),
    ('lv_3', 'lv_4', 28, 30, '', None),
    ('lv_4', 'lv_2', 12, 14, 'lv_gate', 'lv_4'),
    ('lv_4', 'lv_5', 20, 23, 'lv_boss', 'lv_4'),
    ('lv_1', 'lv_6', 31, 33, '', None),
    ('lv_3', 'lv_7', 45, 47, '', None),
    ('lv_4', 'lv_8', 56, 58, '', None),
    ('lv_7', 'lv_8', 44, 46, '', None),
    ('lv_4', 'lv_x', 58, 60, '', None),
    # 神秘の塔
    ('tw_1', 'tw_2', 27, 29, '', None),
    ('tw_2', 'tw_3', -26, -24, '', None),
    ('tw_3', 'tw_4', -26, -24, '', None),
    ('tw_1', 'tw_5', -8, -6, '', None),
    # 霧の谷（2026-11-26）
    ('gr_6', 'mv_1', 60, 62, 'mist_gate', 'gr_6'),   # 霧の門（地方のぬしを2体倒すと、沼の小道の側から開けられる）
    ('mv_1', 'mv_2', 62, 64, '', None),
    ('mv_1', 'mv_6', 36, 38, '', None),
    ('mv_2', 'mv_3', 52, 54, '', None),
    ('mv_6', 'mv_3', 82, 84, '', None),
    ('mv_3', 'mv_4', 78, 80, '', None),
    ('mv_4', 'mv_2', 62, 64, 'mv_gate', 'mv_4'),
    ('mv_4', 'mv_5', 74, 77, 'mv_boss', 'mv_4'),     # 闇の砦の門（村のお守りで開く）
]

def _link_exits(a, b, g0, g1, door, opener):
    ax, ay = AREAS[a]['origin']; aw, ah = AREAS[a]['size']
    bx, by = AREAS[b]['origin']; bw, bh = AREAS[b]['size']
    if ax + aw == bx:
        ea, eb, oa, ob = 'EAST', 'WEST', ay, by
    elif bx + bw == ax:
        ea, eb, oa, ob = 'WEST', 'EAST', ay, by
    elif ay + ah == by:
        ea, eb, oa, ob = 'SOUTH', 'NORTH', ax, bx
    elif by + bh == ay:
        ea, eb, oa, ob = 'NORTH', 'SOUTH', ax, bx
    else:
        raise SystemExit('辺を接していない: %s %s' % (a, b))
    return [(a, ea, g0 - oa, g1 - oa, b, door, opener == a),
            (b, eb, g0 - ob, g1 - ob, a, door, opener == b)]

# 出口： (エリア, 辺, from, to, 相手, 門の id, この側から開けられるか)
EXITS = [e for l in LINKS for e in _link_exits(*l)]

def exit_cells(area, edge, a, b):
    w, h = AREAS[area]['size']
    out = []
    for i in range(a, b + 1):
        out.append({'NORTH': (i, 0), 'SOUTH': (i, h - 1), 'WEST': (0, i), 'EAST': (w - 1, i)}[edge])
    return out

INWARD = {'NORTH': (0, 1), 'SOUTH': (0, -1), 'WEST': (1, 0), 'EAST': (-1, 0)}

# ---------------------------------------------------------------- 道具
class Grid:
    def __init__(self, w, h, seed):
        self.w, self.h = w, h
        self.H = [[0] * w for _ in range(h)]
        self.O = [['.'] * w for _ in range(h)]
        self.rng = random.Random(seed)
        self.seed = seed
        self.reserved = set()   # 物を置かないマス
        self.hedge = set()      # 道を折り返させる木の列（つなぐ直しでも壊さない）
    def inside(self, x, y):
        return 0 <= x < self.w and 0 <= y < self.h
    def cells(self):
        for y in range(self.h):
            for x in range(self.w):
                yield x, y
    def nb(self, x, y):
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if self.inside(x + dx, y + dy):
                yield x + dx, y + dy

def value_noise(seed, scale):
    rng = random.Random(seed)
    cache = {}
    def lattice(i, j):
        if (i, j) not in cache:
            cache[(i, j)] = rng.random()
        return cache[(i, j)]
    def f(x, y):
        fx, fy = x / scale, y / scale
        i, j = math.floor(fx), math.floor(fy)
        tx, ty = fx - i, fy - j
        sx, sy = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
        a = lattice(i, j) * (1 - sx) + lattice(i + 1, j) * sx
        b = lattice(i, j + 1) * (1 - sx) + lattice(i + 1, j + 1) * sx
        return a * (1 - sy) + b * sy
    return f

def relax(g, region=None):
    """隣との差が1段までになるよう、高い方を下げる。region があれば、その中のマスどうしだけ。"""
    changed = True
    while changed:
        changed = False
        for x, y in g.cells():
            if region and not region(x, y):
                continue
            ns = [g.H[ny][nx] for nx, ny in g.nb(x, y) if not region or region(nx, ny)]
            if not ns:
                continue
            m = min(ns)
            if g.H[y][x] > m + 1:
                g.H[y][x] = m + 1
                changed = True

def clamp_heights(g, lo=0, hi=8):
    for x, y in g.cells():
        g.H[y][x] = max(lo, min(hi, g.H[y][x]))

def line_cells(points, width=0.5):
    out = []
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        n = int(max(abs(x1 - x0), abs(y1 - y0)) * 2) + 1
        for i in range(n + 1):
            t = i / n
            px, py = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
            r = int(math.ceil(width))
            for dy in range(-r, r + 1):
                for dx in range(-r, r + 1):
                    if math.hypot(dx, dy) <= width:
                        c = (int(round(px)) + dx, int(round(py)) + dy)
                        if c not in out:
                            out.append(c)
    return out

def put(g, cells, ch, force=False):
    for x, y in cells:
        if g.inside(x, y) and (force or (x, y) not in g.reserved):
            g.O[y][x] = ch

def flatten(g, x0, y0, x1, y1, h=None, clear=True):
    if h is None:
        h = g.H[(y0 + y1) // 2][(x0 + x1) // 2]
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if g.inside(x, y):
                g.H[y][x] = h
                if clear and g.O[y][x] != 'C':
                    g.O[y][x] = '.'
    return h

def raise_region(g, pred, k):
    for x, y in g.cells():
        if pred(x, y):
            g.H[y][x] += k

def stair(g, cells):
    """cells を順に、1段ずつ変わる階段にする（最初のマスの高さから最後のマスの高さへ）。"""
    a = g.H[cells[0][1]][cells[0][0]]
    b = g.H[cells[-1][1]][cells[-1][0]]
    n = len(cells) - 1
    for i, (x, y) in enumerate(cells):
        g.H[y][x] = round(a + (b - a) * i / n) if n else a
        g.O[y][x] = '.'
        g.reserved.add((x, y))

def scatter(g, ch_weights, density, seed, avoid=None):
    rng = random.Random(seed)
    chars = [c for c, _ in ch_weights]
    weights = [w for _, w in ch_weights]
    for x, y in g.cells():
        if g.O[y][x] != '.' or (x, y) in g.reserved:
            continue
        if avoid and avoid(x, y):
            continue
        if rng.random() < density:
            g.O[y][x] = rng.choices(chars, weights)[0]

# ---------------------------------------------------------------- 歩けるかどうか
def walkable(g, x, y):
    return g.inside(x, y) and g.O[y][x] not in BLOCK and g.H[y][x] >= 0  # 高さ -1 は島の外（塔の空）

def step_ok(g, a, b):
    d = g.H[b[1]][b[0]] - g.H[a[1]][a[0]]
    return -DROP <= d <= CLIMB

def bfs(g, start, reverse=False):
    if not walkable(g, *start):
        return {}
    dist = {start: 0}
    q = deque([start])
    while q:
        c = q.popleft()
        for n in g.nb(*c):
            if n in dist or not walkable(g, *n):
                continue
            if not (step_ok(g, n, c) if reverse else step_ok(g, c, n)):
                continue
            dist[n] = dist[c] + 1
            q.append(n)
    return dist

def carve_to(g, src, targets):
    """src から targets のどれかまで、段差1以内・物なしの道を作る（念のための直し）。"""
    best = {src: 0}
    prev = {}
    pq = [(0, src)]
    goal = None
    while pq:
        d, c = heapq.heappop(pq)
        if c in targets:
            goal = c
            break
        if d > best.get(c, 1e9):
            continue
        for n in g.nb(*c):
            o = g.O[n[1]][n[0]]
            if o in '~_L' or n in g.hedge or g.H[n[1]][n[0]] < 0:
                continue  # 水・奈落・折り返しの生け垣は壊さない
            dh = abs(g.H[n[1]][n[0]] - g.H[c[1]][c[0]])
            cost = 1 + (8 if o in WALLS else 0) + 40 * max(0, dh - 1)
            nd = d + cost
            if nd < best.get(n, 1e9):
                best[n] = nd
                prev[n] = c
                heapq.heappush(pq, (nd, n))
    if goal is None:
        raise SystemExit('道を作れない: %s %s' % (getattr(g, 'name', '?'), src))
    path = [goal]
    while path[-1] != src:
        path.append(prev[path[-1]])
    path.reverse()
    for i in range(1, len(path)):
        (px, py), (x, y) = path[i - 1], path[i]
        if g.O[y][x] in WALLS:
            g.O[y][x] = '.'
        if abs(g.H[y][x] - g.H[py][px]) > 1:
            g.H[y][x] = g.H[py][px] + (1 if g.H[y][x] > g.H[py][px] else -1)
    return len(path)

def connect(g, hub, must):
    """must のマスが hub と行き来できるようにする。"""
    for _ in range(40):
        fwd, back = bfs(g, hub), bfs(g, hub, reverse=True)
        both = set(fwd) & set(back)
        missing = [m for m in must if m not in both]
        if not missing:
            return
        m = missing[0]
        g.O[m[1]][m[0]] = '.' if g.O[m[1]][m[0]] in WALLS else g.O[m[1]][m[0]]
        print('  つなぐ:', g.name, m, '道', carve_to(g, m, both))
    raise SystemExit('つながらない: %s' % g.name)

def fill_pockets(g, hub):
    """行けるが戻れないマスを茂みでふさぐ。"""
    while True:
        fwd, back = bfs(g, hub), set(bfs(g, hub, reverse=True))
        trap = [c for c in fwd if c not in back]
        if not trap:
            return
        for x, y in trap:
            if (x, y) in g.reserved:
                raise SystemExit('大事なマスがくぼみになった: %s %s' % (g.name, (x, y)))
            g.O[y][x] = 'B'

def flats_ok(g, size=12, exempt=lambda x, y: False):
    """同じ高さの平地が size×size の四角を含まないか。"""
    for y0 in range(g.h - size + 1):
        for x0 in range(g.w - size + 1):
            if exempt(x0 + size // 2, y0 + size // 2):
                continue
            h = g.H[y0][x0]
            if all(g.H[y][x] == h for y in range(y0, y0 + size) for x in range(x0, x0 + size)):
                return (x0, y0)
    return None

# ---------------------------------------------------------------- エリアの共通の下ごしらえ
def new_area(name, seed):
    w, h = AREAS[name]['size']
    g = Grid(w, h, seed)
    g.name = name
    g.exits = [e for e in EXITS if e[0] == name]
    g.enemies = []   # (x, y, dir, kind)
    g.pickups = []   # (x, y, kind, amount)
    g.pads = []
    g.theme = AREAS[name]['theme']
    g.gimmicks = []   # (id, 種類, ふさぐマス, 当てるマス)
    g.raise_to = {}   # CRYSTAL の足場：マス → 開けたときの高さ（2026-11-26）
    g.bosses = []     # (x, y, 名前, 色)
    g.merchants = []  # (x, y, お店の id)
    g.region = REGION[name]
    g.locked = set()  # 仕掛けを開けるまで行けないマス（拾いもの・出口）。つながりの確かめから外す
    g.open_flat = False  # 広場（たき火・町・ボスの間）。広い平地があってよい
    g.must_extra = []    # つながっていなければならないマス（仕掛けの前・像の前・商人の前など）
    g.start = None
    # 出口と、その内側3マスには物を置かない
    for e in g.exits:
        for c in exit_cells(name, e[1], e[2], e[3]):
            for k in range(4):
                dx, dy = INWARD[e[1]]
                g.reserved.add((c[0] + dx * k, c[1] + dy * k))
    return g

def noise_heights(g, base_fn, fine=1.6, fine_scale=3.5):
    n1 = value_noise(g.seed * 7 + 1, fine_scale)
    for x, y in g.cells():
        g.H[y][x] = int(math.floor(base_fn(x, y) + fine * n1(x, y)))
    clamp_heights(g)
    relax(g)

def flatten_exits(g):
    for e in g.exits:
        cells = exit_cells(g.name, e[1], e[2], e[3])
        dx, dy = INWARD[e[1]]
        mid = cells[len(cells) // 2]
        h = g.H[mid[1] + dy * 2][mid[0] + dx * 2]
        for c in cells:
            for k in range(4):
                x, y = c[0] + dx * k, c[1] + dy * k
                g.H[y][x] = h
                g.O[y][x] = '.'
        # 出口の両どなりのマスは木（地方によって岩・柱）で縁取る（どこが出口かを分かりやすく）
        along = (1, 0) if e[1] in ('NORTH', 'SOUTH') else (0, 1)
        border = {'mountain': 'R', 'lava': 'R', 'castle': 'I', 'tower': 'I', 'mist': 'k'}.get(getattr(g, 'theme', 'grass'), 'P')
        for x, y in ((cells[0][0] - along[0], cells[0][1] - along[1]), (cells[-1][0] + along[0], cells[-1][1] + along[1])):
            if g.inside(x, y) and (x, y) not in g.reserved and g.H[y][x] >= 0:
                g.O[y][x] = border

def exit_height(g, e):
    c = exit_cells(g.name, e[1], e[2], e[3])[0]
    return g.H[c[1]][c[0]]

def set_exit_height(g, e, h):
    """出口と、その内側3マスの高さを h にする（となりのエリアと境目の高さをそろえる）。"""
    dx, dy = INWARD[e[1]]
    for c in exit_cells(g.name, e[1], e[2], e[3]):
        for k in range(4):
            g.H[c[1] + dy * k][c[0] + dx * k] = h

def match_seams(gs):
    """出口でつながる2つのエリアの、境目の高さをそろえる（大陸として違和感なくつながるように）。"""
    for e in EXITS:
        if e[0] > e[4]:
            continue  # 組ごとに1回だけ
        other = next(o for o in EXITS if o[0] == e[4] and o[4] == e[0] and o[5] == e[5])
        a, b = gs[e[0]], gs[e[4]]
        h = max(exit_height(a, e), exit_height(b, other))  # 低い側に坂を作る（高い側を掘り下げると、生け垣を壊す道ができやすい）
        set_exit_height(a, e, h)
        set_exit_height(b, other, h)
        ease_seam(a, e, h)
        ease_seam(b, other, h)
        print('  境目 %s-%s の高さ %d' % (e[0], e[4], h))

def ease_seam(g, e, h):
    """出口の前の高さを、まわりへなだらかにつなぐ（1マス離れるごとに1段まで）。崖のふちの段差を作らないため。
    大事な所（敵の平地・仕掛け・広場）は変えない。"""
    dx, dy = INWARD[e[1]]
    corridor = [(c[0] + dx * k, c[1] + dy * k) for c in exit_cells(g.name, e[1], e[2], e[3]) for k in range(4)]
    cs = set(corridor)
    for x, y in g.cells():
        if (x, y) in cs or (x, y) in g.hedge or (x, y) in g.reserved or (x, y) in getattr(g, 'locked', set()) or g.H[y][x] < 0:
            continue
        if any(a <= x <= c and b <= y <= d for a, b, c, d in g.pads):
            continue
        d = min(max(abs(x - cx), abs(y - cy)) for cx, cy in corridor)
        if d <= 8:
            g.H[y][x] = max(h - d, min(h + d, g.H[y][x]))

def pad(g, x, y, r=3):
    """敵1のための6×6の平地（撃つ敵は r=2 で4×4）。"""
    h = flatten(g, x - r, y - r, x + r - 1, y + r - 1)
    for yy in range(y - r, y + r):
        for xx in range(x - r, x + r):
            g.reserved.add((xx, yy))
    g.pads.append((x - r, y - r, x + r - 1, y + r - 1))
    return h

def enemy(g, x, y, kind, d='RIGHT'):
    g.enemies.append((x, y, d, kind, REGION_LEVEL[g.region]))
    g.reserved.add((x, y))
    g.O[y][x] = '.'

def pickup(g, x, y, kind, amount):
    g.pickups.append((x, y, kind, amount))
    g.reserved.add((x, y))
    g.O[y][x] = '.'

THEME_DECO = {
    'mountain': ([('R', 6), ('P', 2), ('B', 1)], 0.11),
    'grass':    ([('T', 2), ('B', 2), ('F', 3), ('g', 4)], 0.15),
    'lava':     ([('R', 5), ('B', 0)], 0.08),
    'castle':   ([('T', 1), ('B', 2), ('F', 2), ('I', 1)], 0.07),
    'tower':    ([('I', 1)], 0.015),
    'town':     ([('T', 2), ('F', 3), ('B', 1)], 0.08),
    'mist':     ([('k', 4), ('P', 2), ('R', 2), ('B', 1)], 0.12),   # 霧の谷：枯れ木・暗い針葉樹・岩
}
WALL_CH = {'mountain': 'R', 'grass': 'T', 'lava': 'R', 'castle': 'W', 'tower': 'W', 'town': 'T', 'mist': 'k'}
# ボスの像の色
BOSS_TINT = {'岩転がしの巨人': '8d8f94', '草むらの大蛇': '6f9a5a', '満ち引きする溶岩': '7a4a3a', '廃城の主': '8a7f9a',
             '双子（左）': 'c9c3b6', '双子（右）': 'c9c3b6', 'らせん塔の番人': 'b8b2a4', 'ブライト': 'e8e2f0',
             '岩窟のぬし': '6a6c73', '溶岩洞のぬし': '9a3a2a', '女王蜂': 'f0c030', '宝箱の王': 'e8b83a', '闇の王': '3a3448'}


# 2026-11-26（3回目の直し）：高低差をもっと。ノイズの起伏を1.5倍、高台の崖を2段から3段に。
HEIGHT_BOOST = 1.5
MESA_RISE = 3

def field(name, seed, base, amp, fine=1.5, tilt=(0.0, 0.0), scale=11):
    g = new_area(name, seed)
    nb = value_noise(seed * 11 + 3, scale)
    amp *= HEIGHT_BOOST
    noise_heights(g, lambda x, y: base + amp * nb(x, y) + tilt[0] * x / g.w + tilt[1] * y / g.h, fine=fine * 1.2)
    return g

def mesas(g, n, seed, rise=2, r=(3, 6)):
    """崖で囲まれた高台を足す。1か所だけ、外へ1段ずつ下る階段をつける。"""
    rng = random.Random(seed)
    for _ in range(n):
        rx, ry = rng.uniform(*r), rng.uniform(*r)
        cx, cy = rng.randint(int(rx) + 2, g.w - int(rx) - 3), rng.randint(int(ry) + 2, g.h - int(ry) - 3)
        inside = [(x, y) for x, y in g.cells() if math.hypot((x - cx) / rx, (y - cy) / ry) < 1.0]
        if any(c in g.reserved for c in inside):
            continue
        top = min(8, max(g.H[y][x] for x, y in inside) + rise)
        for x, y in inside:
            g.H[y][x] = top
        dx, dy = rng.choice([(1, 0), (-1, 0), (0, 1), (0, -1)])
        x, y = cx, cy
        while (x, y) in inside:
            x, y = x + dx, y + dy
        cells = [(x - dx, y - dy)]
        for k in range(rise + 2):
            if g.inside(x + dx * k, y + dy * k):
                cells.append((x + dx * k, y + dy * k))
        if len(cells) >= 3:
            stair(g, cells)

def scatter_theme(g, seed, density=None, avoid=None):
    items, d = THEME_DECO[g.theme]
    items = [(c, w) for c, w in items if w > 0]
    scatter(g, items, d if density is None else density, seed, avoid=avoid)

def river(g, points, ch, width=0.7, gaps=(), bridge=None):
    """川（水・溶岩）。gaps の番号の所は渡れる（溶岩は地面、水は bridge の記号）。"""
    cells = line_cells(points, width)
    for i, (x, y) in enumerate(cells):
        if not g.inside(x, y) or (x, y) in g.reserved:
            continue
        gap = any(abs(i - k) <= 2 for k in gaps)
        if gap:
            if bridge:
                g.O[y][x] = bridge
                g.reserved.add((x, y))
            continue
        g.O[y][x] = ch
        g.reserved.add((x, y))

def ruins(g, n, seed):
    """崩れた石の建物：石の壁の四角に、すき間と柱。中は石畳。"""
    rng = random.Random(seed)
    for _ in range(n):
        w, h = rng.randint(4, 7), rng.randint(3, 5)
        x0, y0 = rng.randint(2, g.w - w - 3), rng.randint(2, g.h - h - 3)
        ring = [(x, y) for x in range(x0, x0 + w + 1) for y in range(y0, y0 + h + 1)
                if x in (x0, x0 + w) or y in (y0, y0 + h)]
        if any(c in g.reserved for c in ring):
            continue
        gaps = set()
        for _ in range(rng.randint(2, 3)):
            c = rng.choice(ring)
            gaps |= {c, (c[0] + 1, c[1]), (c[0], c[1] + 1)}
        for c in ring:
            if c not in gaps and g.H[c[1]][c[0]] >= 0:
                corner = c[0] in (x0, x0 + w) and c[1] in (y0, y0 + h)
                g.O[c[1]][c[0]] = 'I' if corner else 'W'
        for x in range(x0 + 1, x0 + w):
            for y in range(y0 + 1, y0 + h):
                if g.O[y][x] == '.':
                    g.O[y][x] = 's'

def grass_patches(g, seed, threshold=0.62, ch='g'):
    n = value_noise(seed, 5)
    for x, y in g.cells():
        if g.O[y][x] == '.' and (x, y) not in g.reserved and n(x, y) > threshold:
            g.O[y][x] = ch

def protect(g, cells):
    for c in cells:
        g.reserved.add(c)
        g.hedge.add(c)

OUT_OF = {'N': (0, -1), 'S': (0, 1), 'E': (1, 0), 'W': (-1, 0)}
GIMMICK_CH = {'CRACK': 'X', 'THORNS': 'Y', 'VINES': 'V', 'PLATE': 'E', 'LEVER': 'E', 'BRITTLE': 'N'}
## 2026-11-26：仕掛けの、武器を当てる所（押し板 U は歩ける。レバー J・水晶 Z は通れない）
SWITCH_CH = {'PLATE': 'U', 'LEVER': 'J', 'CRYSTAL': 'Z'}

def pocket(g, kind, x0, y0, x1, y1, side, reward):
    """囲われた小さな所（中に宝）。side の辺の真ん中が入口で、そこを仕掛けがふさぐ。"""
    ox, oy = OUT_OF[side]
    mx, my = (x0 + x1) // 2, (y0 + y1) // 2
    gate = {'N': (mx, y0 - 1), 'S': (mx, y1 + 1), 'E': (x1 + 1, my), 'W': (x0 - 1, my)}[side]
    ap = (gate[0] + ox, gate[1] + oy)
    stand = (ap[0] + ox, ap[1] + oy)
    allc = [(x, y) for x in range(x0 - 1, x1 + 2) for y in range(y0 - 1, y1 + 2)] + [ap, stand]
    for c in allc:
        if not g.inside(*c) or (c in g.reserved and c not in g.hedge):
            raise SystemExit('仕掛けの所が空いていない: %s %s %s' % (g.name, kind, c))
    A = g.H[ap[1]][ap[0]]
    if kind == 'CRACK':
        A = max(A, 1)
        floor = A - 1
    elif kind == 'CRYSTAL':
        A = min(A, 5)
        floor = A + 3   # 中は3段高い台。水晶を光らせると、入口に2段の足場がせり上がる
    else:
        floor = A
    sw = None
    if kind in SWITCH_CH:
        # 板・レバー・水晶は、立つ所（stand）の横。押し板は1マスあけて置く（となりに立って鉄球を落とす）
        far_k = 1 if kind == 'LEVER' else 2
        for px, py in ((oy, ox), (-oy, -ox)):
            cand = (stand[0] + px * far_k, stand[1] + py * far_k)
            mid = (stand[0] + px, stand[1] + py)
            if all(g.inside(*c) and c not in g.reserved and c not in allc for c in (cand, mid)):
                sw, sw_mid = cand, mid
                break
        if sw is None:
            raise SystemExit('仕掛けの所が空いていない: %s %s 板・レバー・水晶' % (g.name, kind))
        for c in {sw, sw_mid}:
            g.H[c[1]][c[0]] = A
            g.O[c[1]][c[0]] = '.'
        g.O[sw[1]][sw[0]] = SWITCH_CH[kind]
        if kind == 'PLATE':
            g.reserved.add(sw)
            g.must_extra.append(sw)
        else:
            protect(g, [sw])
        g.reserved.add(sw_mid)
        g.must_extra.append(sw_mid)
    for c in (ap, stand):
        g.H[c[1]][c[0]] = A
        g.O[c[1]][c[0]] = '.'
        g.reserved.add(c)
    inner = [(x, y) for x in range(x0, x1 + 1) for y in range(y0, y1 + 1)]
    for x, y in inner:
        g.H[y][x] = floor
        g.O[y][x] = '.'
    wall = WALL_CH[g.theme]
    for x, y in allc[:-2]:
        if (x, y) in inner or (x, y) == gate:
            continue
        g.O[y][x] = wall
        g.H[y][x] = max(g.H[y][x], floor)
    protect(g, allc[:-2])
    g.locked |= set(inner)
    gid = '%s:%d' % (g.name, len(g.gimmicks))
    g.H[gate[1]][gate[0]] = floor
    if kind == 'TARGET':
        # 入口と、その外の1マスが水。中の奥に的。的を撃つと橋が下りる
        g.H[ap[1]][ap[0]] = floor
        g.O[gate[1]][gate[0]] = '~'
        g.O[ap[1]][ap[0]] = '~'
        g.H[stand[1]][stand[0]] = floor
        tgt = (gate[0] - ox * 2, gate[1] - oy * 2)
        g.O[tgt[1]][tgt[0]] = 'Q'
        g.gimmicks.append((gid, kind, [gate, ap], [tgt]))
        g.locked.add(ap)
        g.must_extra.append(stand)
        far = [c for c in inner if c != tgt and abs(c[0] - gate[0]) + abs(c[1] - gate[1]) > 1]
    elif kind == 'CRYSTAL':
        # 閉じている間は入口と、その外の1マスが低いまま（中の台へは3段で登れない）
        g.H[gate[1]][gate[0]] = A
        g.O[gate[1]][gate[0]] = '.'
        g.raise_to[ap] = A + 1
        g.raise_to[gate] = A + 2
        g.gimmicks.append((gid, kind, [ap, gate], [sw]))
        g.must_extra.append(ap)
        far = inner
    else:
        g.O[gate[1]][gate[0]] = GIMMICK_CH[kind]
        g.gimmicks.append((gid, kind, [gate], [sw] if sw else [gate]))
        g.must_extra.append(ap)
        far = inner
    rx, ry = max(far, key=lambda c: abs(c[0] - gate[0]) + abs(c[1] - gate[1]))
    pickup(g, rx, ry, reward[0], reward[1])
    g.locked.add((rx, ry))
    g.locked.add(gate)
    return gid

def barrier(g, x, kind, gate_y, ch):
    """西の細い帯を、縦の川（水か溶岩）で切り離す。gate_y の所だけ仕掛けで渡れる。帯の中の出口は仕掛けを開けるまで行けない。"""
    for y in range(g.h):
        for xx in (x, x + 1):
            if y == gate_y:
                continue
            g.O[y][xx] = ch
            g.H[y][xx] = max(0, g.H[y][xx])
            g.reserved.add((xx, y))
            g.hedge.add((xx, y))
    gid = '%s:%d' % (g.name, len(g.gimmicks))
    h = g.H[gate_y][x + 2]
    for xx in range(x - 3, x + 4):
        g.H[gate_y][xx] = h
        g.O[gate_y][xx] = '.'
        g.reserved.add((xx, gate_y))
    for yy in (gate_y - 1, gate_y + 1):
        for xx in range(x - 3, x + 2):
            if g.O[yy][xx] not in (ch,):
                pass
    if kind == 'TARGET':
        g.O[gate_y][x] = '~'
        g.O[gate_y][x + 1] = '~'
        tgt = (x - 3, gate_y - 2)
        g.H[tgt[1]][tgt[0]] = h
        g.O[tgt[1]][tgt[0]] = 'Q'
        protect(g, [tgt])
        g.gimmicks.append((gid, kind, [(x, gate_y), (x + 1, gate_y)], [tgt]))
    else:
        g.O[gate_y][x + 1] = GIMMICK_CH[kind]
        g.gimmicks.append((gid, kind, [(x + 1, gate_y)], [(x + 1, gate_y)]))
    g.must_extra.append((x + 3, gate_y))
    g.locked |= {(xx, yy) for xx in range(0, x) for yy in range(g.h)}
    g.locked |= {(x, gate_y), (x + 1, gate_y)}
    return gid

def boss(g, x, y, name):
    """ボスの居場所。ボスはここに現れて動く（倒したあとは何もない）。
    2026-11-26：高低差を増やしたので、ボスのまわり（半径4マス）は同じ高さの床にする（物は残す）。"""
    disc = [(xx, yy) for xx, yy in g.cells() if math.hypot(xx - x, yy - y) <= 4.2]
    hs = sorted(g.H[yy][xx] for xx, yy in disc if g.H[yy][xx] >= 0)
    if hs:
        h = hs[len(hs) // 2]
        for xx, yy in disc:
            if g.H[yy][xx] >= 0:
                g.H[yy][xx] = h
    g.O[y][x] = '.'
    g.reserved.add((x, y))
    g.bosses.append((x, y, name, BOSS_TINT.get(name, '9a968e')))
    g.must_extra.append((x, y))

def merchant(g, x, y, shop):
    """商人。前（南）に立って F でお店が開く。"""
    g.O[y][x] = 'M'
    protect(g, [(x, y)])
    g.O[y + 1][x] = '.'
    g.reserved.add((x, y + 1))
    g.must_extra.append((x, y + 1))
    g.merchants.append((x, y, shop))

def plaza(g, cx, cy, rx=4, ry=3, paving=False, fire=True):
    h = flatten(g, cx - rx, cy - ry, cx + rx, cy + ry)
    for y in range(cy - ry, cy + ry + 1):
        for x in range(cx - rx, cx + rx + 1):
            g.reserved.add((x, y))
            if paving:
                g.O[y][x] = 's'
    g.pads.append((cx - rx, cy - ry, cx + rx, cy + ry))
    if fire:
        g.open_flat = True   # たき火の広場のあるエリア（休憩所・町）
        g.O[cy][cx] = 'C'
        g.campfire = (cx, cy)
        g.O[cy + 1][cx] = '.' if not paving else 's'
        g.must_extra.append((cx, cy + 1))
    return h

def loot(g, seed, n, table=None):
    """拾いもの（お金・素材・道具）を、たどり着ける所にばらまく。"""
    table = table or LOOT[g.region]
    rng = random.Random(seed)
    free = [(x, y) for x, y in g.cells() if g.O[y][x] in '.Fgs' and (x, y) not in g.reserved and g.H[y][x] >= 0
            and (x, y) not in g.locked]
    rng.shuffle(free)
    placed = []
    for c in free:
        if len(placed) >= n:
            break
        if all(abs(c[0] - p[0]) + abs(c[1] - p[1]) > 6 for p in placed):
            kind, amount = table[(len(placed) + seed) % len(table)]
            pickup(g, c[0], c[1], kind, amount)
            placed.append(c)

# 地方ごとの拾いもの（品物の id と数）
LOOT = {
    'はじまりの地': [('money', 15), ('herb', 2), ('wood', 2), ('potion', 1), ('hide', 2), ('scrap', 2)],
    '山岳': [('iron_ore', 2), ('snow', 2), ('money', 30), ('potion', 1), ('bone', 2), ('arrow', 10)],
    '草原': [('herb', 3), ('scale', 2), ('money', 30), ('potion', 1), ('wood', 2), ('arrow', 10)],
    '廃城': [('old_steel', 2), ('silver', 1), ('money', 40), ('potion_m', 1), ('scrap', 3), ('ether', 1)],
    '溶岩': [('obsidian', 2), ('fire_stone', 2), ('money', 40), ('potion_m', 1), ('bomb', 2)],
    '神秘の塔': [('star_shard', 1), ('silver', 2), ('money', 60), ('potion_m', 1), ('ether', 1)],
    '霧の谷': [('mist_moss', 2), ('dark_shard', 1), ('money', 50), ('potion_m', 1), ('ether', 1), ('arrow', 10)],
}

# 地方ごとの敵の種類（EnemyKind.Kind の名前）
REGION_ENEMIES = {
    'はじまりの地': ['WEAK', 'MELEE', 'SHOOTER'],
    '山岳': ['MELEE', 'CHARGER', 'LOBBER', 'FLYER', 'SPEAR', 'WASP'],
    '草原': ['WEAK', 'CHARGER', 'SHADOW', 'LOBBER', 'BEETLE', 'WASP'],
    '廃城': ['SHIELD', 'GHOST', 'SPEAR', 'MAGE', 'MIMIC', 'SHOOTER'],
    '溶岩': ['BOMBER', 'FLYER', 'SHIELD', 'BEETLE', 'MIMIC', 'SHOOTER'],
    '神秘の塔': ['SHADOW', 'GHOST', 'MAGE', 'SPEAR', 'FLYER', 'SHIELD'],
    '霧の谷': ['WOLF', 'DARK_KNIGHT', 'GHOST', 'WOLF', 'SHADOW', 'LOBBER'],   # 2026-11-26：狼と黒騎士
}
FLAT_KINDS = {'CHARGER'}   # 段差を登らない敵（4×4の平地を作る）。2026-11-25 夜からイノシシだけ
DIR_NAMES = ['RIGHT', 'DOWN', 'LEFT', 'UP']

def spawn(g, seed, n, kinds=None):
    """敵を n 体置く。出口・たき火・仕掛けから離れた、たどり着ける所。敵どうしも離す。"""
    kinds = kinds or REGION_ENEMIES[g.region]
    rng = random.Random(seed)
    exits = [c for e in g.exits for c in exit_cells(g.name, *e[1:4])]
    fire = getattr(g, 'campfire', None)
    cand = [(x, y) for x, y in g.cells() if 2 <= x < g.w - 2 and 2 <= y < g.h - 2]
    rng.shuffle(cand)
    placed = 0
    for i in range(n):
        kind = kinds[(i + seed) % len(kinds)]
        for (x, y) in cand:
            if g.O[y][x] not in '.Fgs' or (x, y) in g.reserved or (x, y) in g.locked or g.H[y][x] < 0:
                continue
            if min(max(abs(x - ex), abs(y - ey)) for ex, ey in exits) < 4:
                continue
            if fire and max(abs(x - fire[0]), abs(y - fire[1])) < 5:
                continue
            if any(max(abs(x - ex), abs(y - ey)) < 4 for ex, ey, *_ in g.enemies):
                continue
            if any(max(abs(x - bx), abs(y - by)) < 7 for bx, by, *_ in g.bosses):
                continue
            if kind in FLAT_KINDS:
                sq = [(xx, yy) for xx in range(x - 2, x + 2) for yy in range(y - 2, y + 2)]
                if any(not g.inside(*c) or c in g.reserved or c in g.locked or c in g.hedge or g.O[c[1]][c[0]] in '~_L'
                       or g.H[c[1]][c[0]] < 0 for c in sq):
                    continue
                hs = [g.H[c[1]][c[0]] for c in sq]
                if max(hs) - min(hs) > 1:
                    continue
                pad(g, x, y, 2)
            enemy(g, x, y, kind, DIR_NAMES[(x + y) % 4])
            placed += 1
            break
    if placed < n:
        print('  敵を置けなかった:', g.name, n - placed)

def region_field(name, seed, base, amp, mesa_n=3, fine=1.5, tilt=(0.0, 0.0), pre=None):
    g = field(name, seed, base, amp, fine=fine, tilt=tilt)
    if pre:
        pre(g)   # 仕掛け・たき火などを先に置く（高台がかぶらないように）
    if g.theme == 'mountain':
        mesas(g, mesa_n + 1, seed + 1, rise=MESA_RISE, r=(2, 4))
    elif g.theme == 'castle':
        mesas(g, max(1, mesa_n), seed + 1, rise=MESA_RISE, r=(2, 3.5))
    else:
        mesas(g, mesa_n + (1 if mesa_n > 0 else 0), seed + 1, rise=MESA_RISE, r=(2, 3.5))
    return g

def dress(g, seed):
    """地方の飾りを足し、出口の前を平らにする。"""
    if g.theme == 'grass':
        grass_patches(g, seed + 5)
    if g.theme == 'castle':
        ruins(g, max(1, g.w * g.h // 200), seed + 6)
    if g.theme == 'mist':
        grass_patches(g, seed + 5, threshold=0.66)   # 霧の谷の背の高い草
    scatter_theme(g, seed + 7)
    flatten_exits(g)


def area(name, seed, base, amp, mesa_n=2, fine=1.4, tilt=(0.0, 0.0), pre=None, enemies=4, loot_n=3, after=None):
    """地方のふつうのエリア：ノイズの地形・高台・仕掛け（pre）・飾り・敵・拾いもの。"""
    g = region_field(name, seed, base, amp, mesa_n=mesa_n, fine=fine, tilt=tilt, pre=pre)
    if after:
        after(g)
    dress(g, seed)
    spawn(g, seed + 3, enemies)
    loot(g, seed + 2, loot_n)
    return g

def carve_rest(g, cx, cy, rx, ry, keep_cells=()):
    """休憩所をせまくする（2026-11-25 夜の2回目の直し）。たき火の広場のまわりと、出口へ向かう3マスの道だけを残し、
    ほかは島の外（深い谷）にする。歩ける所が小さな台地になり、迷わずに次へ進める。"""
    keep = set(keep_cells)
    g.rest_shape = (rx, ry)   # 広げたあとにもう一度せまくするのに使う
    n = value_noise(g.seed * 5 + 9, 2.5)
    for x, y in g.cells():
        if math.hypot((x - cx) / (rx + 1.2), (y - cy) / (ry + 1.2)) + 0.3 * (n(x, y) - 0.5) <= 1.0:
            keep.add((x, y))
    for e in g.exits:
        cells = exit_cells(g.name, e[1], e[2], e[3])
        dx, dy = INWARD[e[1]]
        mx, my = cells[len(cells) // 2]
        x, y = mx, my
        # 出口から内側へ、広場の中心と同じ列（行）まで進む
        while (dx != 0 and x != cx) or (dy != 0 and y != cy):
            for k in (-1, 0, 1):
                keep.add((x + k * abs(dy), y + k * abs(dx)))
            x += dx; y += dy
        # そこから広場の中心へ
        sx = 0 if x == cx else (1 if cx > x else -1)
        sy = 0 if y == cy else (1 if cy > y else -1)
        while (x, y) != (cx, cy):
            for k in (-1, 0, 1):
                for j in (-1, 0, 1):
                    keep.add((x + k, y + j))
            x += sx; y += sy
        for c in cells:
            keep.add(c)
            # 着いた所（出口の1マス内側）から歩き出せるように、出口の幅のまま2マス入る
            keep.add((c[0] + dx, c[1] + dy))
            keep.add((c[0] + 2 * dx, c[1] + 2 * dy))
    for x, y in g.cells():
        if (x, y) not in keep:
            g.H[y][x] = -1
            g.O[y][x] = '.'
    return keep

def clear_void(g):
    """島の外のマスには物を置かない（飾りをまいた後に消す）。"""
    for x, y in g.cells():
        if g.H[y][x] < 0:
            g.O[y][x] = '.'

def rest(name, seed, base, amp, cx, cy, mx, my, shop=None, paving=False, enemies=0, rx=3, ry=2):
    """休憩所：たき火の広場と旅の商人。2026-11-25 夜（2回目の直し）から、せまくして敵を置かない。"""
    def _pre(g):
        plaza(g, cx, cy, rx=rx, ry=ry, paving=paving)
        if shop:
            merchant(g, mx, my, shop)
    g = region_field(name, seed, base, amp, mesa_n=0, fine=1.0, pre=_pre)
    carve_rest(g, cx, cy, rx, ry, keep_cells=[(x, y) for x, y in g.cells() if g.O[y][x] == 'M'] +
               [(mx + i, my + j) for i in (-1, 0, 1) for j in (-1, 0, 1, 2)] if shop else [])
    dress(g, seed)
    clear_void(g)
    spawn(g, seed + 3, enemies)
    loot(g, seed + 2, 2)
    return g

# ---------------------------------------------------------------- はじまりの町（前の野営地。2026-11-25 に町へ作り替えた）
def make_town():
    g = new_area('town', 601)
    n = value_noise(611, 5)
    for x, y in g.cells():
        g.H[y][x] = 1 + (1 if n(x, y) > 0.75 else 0)
    plaza(g, 12, 10, rx=5, ry=3, paving=True)
    for (x0, y0, x1, y1) in [(2, 2, 6, 5), (16, 2, 21, 5), (7, 15, 10, 17), (18, 15, 21, 17)]:
        flatten(g, x0 - 1, y0 - 1, x1 + 1, y1 + 1, 1)
        for x in range(x0, x1 + 1):
            for y in range(y0, y1 + 1):
                g.O[y][x] = 'H'
        protect(g, [(x, y) for x in range(x0 - 1, x1 + 2) for y in range(y0 - 1, y1 + 2)])
        for x in range(x0 - 1, x1 + 2):
            for y in range(y0 - 1, y1 + 2):
                if g.O[y][x] != 'H':
                    g.O[y][x] = '.'
    flatten(g, 3, 12, 5, 14, 1)
    g.O[13][4] = 'O'   # 井戸
    protect(g, [(4, 13)])
    merchant(g, 8, 7, 'tool')     # 道具屋
    merchant(g, 12, 7, 'weapon')  # 武器屋
    merchant(g, 16, 7, 'smith')   # 鍛冶屋
    pickup(g, 9, 12, 'money', 30)
    pickup(g, 15, 12, 'potion', 2)
    flatten_exits(g)
    for x, y in g.cells():
        if (x in (0, 23) or y in (0, 19)) and (x, y) not in g.reserved:
            g.O[y][x] = g.rng.choice('TPTB')
    scatter_theme(g, 607, avoid=lambda x, y: g.O[y][x] == 's')
    g.start = (12, 11)
    return g

# ---------------------------------------------------------------- はじまりの地
def make_rocks():
    def _pre(g):
        pocket(g, 'CRACK', 15, 12, 17, 14, 'W', ('money', 30))
        pocket(g, 'PLATE', 7, 2, 9, 4, 'S', ('bomb', 2))   # 押し板に鉄球を置くと鉄格子が上がる（2026-11-26）
    def _after(g):
        scatter(g, [('R', 6), ('B', 2), ('P', 1)], 0.10, 7)
    return area('rocks', 5, 1.0, 3.5, mesa_n=2, fine=1.6, pre=_pre, after=_after, enemies=4, loot_n=3)

def make_hills():
    def _pre(g):
        river(g, [(13, 0), (11, 9), (14, 17), (12, 25)], '~', 0.7, gaps=(10, 34), bridge='=')
        pocket(g, 'LEVER', 18, 18, 20, 20, 'W', ('potion_m', 1))
    def _after(g):
        loot(g, 97, 1, [('sword_bronze', 1)])
    return area('hills', 9, 0.6, 2.6, mesa_n=2, fine=1.4, pre=_pre, after=_after, enemies=5, loot_n=3)

def make_forest():
    g = new_area('forest', 13)
    nb = value_noise(131, 9)
    noise_heights(g, lambda x, y: 2.0 + 2.0 * nb(x, y) + (17 - y) / 17.0 * 1.0, fine=1.3)
    # 西の台地（崖で囲まれた高い所、5〜6段）。北東の階段からだけ登れる
    for x, y in g.cells():
        if x < 7 and 2 <= y < 13:
            g.H[y][x] = 6
    for y in range(2, 13):
        g.H[y][7] = min(g.H[y][7], 3)
    relax(g, lambda x, y: x >= 7)
    stair(g, [(11, 1), (10, 1), (9, 1), (8, 1), (7, 1), (6, 1), (5, 2)])
    g.H[1][5] = 6
    pickup(g, 3, 6, 'ball_heavy', 1)   # 台地の上の宝箱（重い鉄球。武器屋でも売っている）
    protect(g, [(x, y) for x in range(7) for y in range(2, 13)])
    scatter(g, [('P', 4), ('T', 3), ('B', 1)], 0.14, 17)
    flatten_exits(g)
    spawn(g, 15, 4, ['MELEE', 'SHOOTER', 'WEAK', 'MELEE'])
    loot(g, 14, 3)
    return g

# ---------------------------------------------------------------- 山岳
def make_mt_1():
    def _pre(g):
        pocket(g, 'CRACK', 3, 3, 5, 5, 'S', ('iron_ore', 4))
    return area('mt_1', 201, 1.5, 3.5, mesa_n=3, pre=_pre, enemies=4)

def make_mt_2():
    return rest('mt_2', 211, 2.5, 2.0, 8, 9, 6, 7, shop='山岳')

def make_mt_3():
    def _pre(g):
        barrier(g, 4, 'TARGET', 13, '~')
    return area('mt_3', 221, 2.5, 3.5, mesa_n=2, pre=_pre, enemies=4)

def make_mt_4():
    def _pre(g):
        pocket(g, 'VINES', 26, 3, 28, 5, 'W', ('arrow_iron', 10))
    return area('mt_4', 231, 3.0, 3.0, mesa_n=4, tilt=(0.0, -1.0), pre=_pre, enemies=5, loot_n=4)

def make_mt_5():
    g = field('mt_5', 241, 2.0, 1.0, fine=0.8)
    g.open_flat = True
    for x, y in g.cells():
        if 5 <= x <= 18 and 2 <= y <= 8:
            g.H[y][x] = 7   # 巨人の岩棚（まわりより4段以上高い）
        elif g.H[y][x] > 3:
            g.H[y][x] = 3
    stair(g, [(3, 15), (3, 14), (3, 13), (3, 12), (3, 11), (3, 10), (3, 9), (3, 8), (4, 8), (5, 8)])
    protect(g, [(x, y) for x in range(5, 19) for y in range(2, 9)])
    boss(g, 12, 5, '岩転がしの巨人')
    for x, y in g.cells():
        if (x, y) not in g.reserved and g.O[y][x] == '.' and random.Random(x * 99 + y).random() < 0.05 and y > 10:
            g.O[y][x] = 'R'
    flatten_exits(g); loot(g, 242, 2); return g

def make_mt_x():
    g = field('mt_x', 251, 2.0, 1.0, fine=0.6)
    g.open_flat = True
    for x, y in g.cells():
        if math.hypot((x - 9) / 8.5, (y - 7) / 6.5) > 1.0:
            g.O[y][x] = 'R'
    boss(g, 6, 7, '岩窟のぬし')
    flatten_exits(g); loot(g, 252, 2, [('iron_ore', 4), ('money', 50)]); return g

# ---------------------------------------------------------------- 草原
def make_gr_1():
    def _pre(g):
        pocket(g, 'CRACK', 3, 10, 5, 12, 'N', ('money', 40))
        pocket(g, 'PLATE', 18, 11, 20, 13, 'W', ('herb', 4))
        river(g, [(15, 0), (14, 8), (16, 15)], '~', 0.7, gaps=(12,), bridge='=')
    return area('gr_1', 301, 0.8, 2.4, mesa_n=2, fine=1.3, pre=_pre, enemies=4)

def make_gr_2():
    return rest('gr_2', 311, 1.0, 1.2, 8, 11, 6, 9, shop='草原')

def make_gr_3():
    def _pre(g):
        pocket(g, 'THORNS', 2, 2, 4, 4, 'S', ('potion_m', 2))
    def _after(g):
        grass_patches(g, 329, threshold=0.55, ch='F')
    return area('gr_3', 321, 1.2, 2.6, mesa_n=2, pre=_pre, after=_after, enemies=4)

def make_gr_4():
    def _pre(g):
        pocket(g, 'TARGET', 5, 27, 7, 29, 'N', ('bow_poison', 1))
    def _after(g):
        grass_patches(g, 338, threshold=0.5)
    return area('gr_4', 331, 1.0, 2.2, mesa_n=3, pre=_pre, after=_after, enemies=5, loot_n=4)

def make_gr_5():
    g = field('gr_5', 341, 0.8, 1.2, fine=0.8, scale=12)
    g.open_flat = True
    boss(g, 14, 10, '草むらの大蛇')
    for x, y in g.cells():
        if (x, y) in g.reserved or g.O[y][x] != '.':
            continue
        d = math.hypot((x - 13) / 10.0, (y - 10) / 8.0)
        r = random.Random(x * 131 + y * 7).random()
        if d < 1.0 and r < 0.7:
            g.O[y][x] = 'g'
        elif d >= 1.0 and r < 0.25:
            g.O[y][x] = random.Random(x + y * 57).choice('TBTF')
    flatten_exits(g); loot(g, 342, 2); return g

# ---------------------------------------------------------------- 廃城
def make_cs_1():
    def _pre(g):
        pocket(g, 'VINES', 16, 6, 18, 8, 'W', ('armor_mage', 1))
        pocket(g, 'LEVER', 3, 3, 5, 5, 'S', ('old_steel', 3))
    return area('cs_1', 401, 1.0, 2.2, mesa_n=2, fine=1.2, pre=_pre, enemies=4)

def make_cs_2():
    return rest('cs_2', 411, 1.5, 1.5, 9, 9, 11, 7, shop='廃城', paving=True)

def make_cs_3():
    def _pre(g):
        pocket(g, 'CRACK', 3, 10, 5, 12, 'E', ('silver', 4))
    return area('cs_3', 421, 1.5, 2.6, mesa_n=2, pre=_pre, enemies=4)

def make_cs_4():
    def _pre(g):
        pocket(g, 'THORNS', 27, 3, 29, 5, 'W', ('potion_l', 1))
    return area('cs_4', 431, 1.5, 2.6, mesa_n=3, pre=_pre, enemies=5, loot_n=4)

def make_cs_5():
    g = field('cs_5', 441, 1.0, 0.5, fine=0.4)
    g.open_flat = True
    flatten(g, 2, 1, 21, 18, 1)
    for x in range(2, 22):
        for y in range(1, 19):
            edge = x in (2, 21) or y in (1, 18)
            if edge and not (y == 18 and 10 <= x <= 15):
                g.O[y][x] = 'W'
            elif x in (3, 4, 19, 20) or y == 2:
                g.H[y][x] = 3   # 崩れた壁の上（高い通り道）
                g.O[y][x] = '.'
            else:
                g.O[y][x] = 's'
    for y in range(5, 16, 4):
        for x in (8, 15):
            g.O[y][x] = 'I'
    stair(g, [(7, 16), (6, 16), (5, 16), (4, 16)])
    stair(g, [(16, 16), (17, 16), (18, 16), (19, 16)])
    for y in range(17, 18):
        for x in range(3, 21):
            if g.H[y][x] > 1:
                g.H[y][x] = 1
                g.O[y][x] = 's'
    boss(g, 12, 6, '廃城の主')
    flatten_exits(g); loot(g, 442, 2); return g

# ---------------------------------------------------------------- 溶岩
def make_lv_1():
    def _pre(g):
        pocket(g, 'CRACK', 13, 3, 15, 5, 'W', ('fire_stone', 3))
        pocket(g, 'BRITTLE', 3, 3, 5, 5, 'S', ('obsidian', 2))   # もろい壁は爆弾で崩れる
        river(g, [(0, 10), (6, 9), (12, 11), (17, 9)], 'L', 0.6, gaps=(5, 22))
    return area('lv_1', 501, 1.5, 2.6, mesa_n=1, pre=_pre, enemies=4)

def make_lv_2():
    return rest('lv_2', 511, 2.0, 1.2, 9, 9, 11, 7, shop='溶岩', rx=2, ry=2)

def make_lv_3():
    def _pre(g):
        pocket(g, 'THORNS', 11, 2, 13, 4, 'S', ('staff_fire_3', 1))
        river(g, [(4, 10), (8, 12), (12, 11), (15, 13)], 'L', 0.6, gaps=(6, 18))
    return area('lv_3', 521, 1.5, 2.6, mesa_n=1, pre=_pre, enemies=4)

def make_lv_4():
    def _pre(g):
        barrier(g, 4, 'VINES', 10, 'L')
    def _after(g):
        river(g, [(10, 6), (16, 8), (22, 6), (30, 8)], 'L', 0.6, gaps=(4, 14, 26))
    return area('lv_4', 531, 2.0, 3.0, mesa_n=3, pre=_pre, after=_after, enemies=5, loot_n=4)

def make_lv_5():
    g = field('lv_5', 541, 4.0, 0.6, fine=0.4)
    g.open_flat = True
    for x, y in g.cells():
        d = math.hypot((x - 12) / 10.0, (y - 10) / 8.0)
        if d < 1.0:
            g.H[y][x] = 1
            if 0.5 < d < 0.7:
                g.O[y][x] = 'L'   # 低い所を囲む溶岩の輪（ボスで満ち引きする所）
    for k, (ix, iy) in enumerate([(6, 6), (18, 6), (6, 14), (18, 14)]):
        for x, y in g.cells():
            if math.hypot(x - ix, y - iy) < 1.8:
                g.H[y][x] = 3 + k % 2
                g.O[y][x] = '.'
    for (x0, y0, x1, y1) in [(11, 0, 13, 6), (11, 14, 13, 19), (0, 9, 6, 11), (18, 9, 23, 11)]:
        for x in range(x0, x1 + 1):
            for y in range(y0, y1 + 1):
                if g.O[y][x] == 'L':
                    g.O[y][x] = '.'
    relax(g)
    boss(g, 12, 10, '満ち引きする溶岩')
    flatten_exits(g); loot(g, 542, 2); return g

def make_lv_x():
    g = field('lv_x', 551, 2.0, 0.8, fine=0.6)
    g.open_flat = True
    for x, y in g.cells():
        if math.hypot((x - 9) / 8.5, (y - 7) / 6.5) > 1.0:
            g.O[y][x] = 'R'
        elif math.hypot(x - 10, y - 3) < 1.6 or math.hypot(x - 11, y - 11) < 1.4:
            g.O[y][x] = 'L'
    boss(g, 5, 7, '溶岩洞のぬし')
    flatten_exits(g); loot(g, 552, 2, [('fire_stone', 4), ('potion_m', 2)]); return g

# ---------------------------------------------------------------- 神秘の塔
def make_tw_1():
    g = field('tw_1', 701, 1.0, 0.8, fine=0.5)
    plaza(g, 10, 11, rx=3, ry=2, paving=True)
    carve_rest(g, 10, 11, 3, 2)   # たき火のエリアはせまく、敵なし（2026-11-25 夜の2回目の直し）
    dress(g, 701)
    clear_void(g)
    loot(g, 702, 2)
    return g

def make_tw_2():
    g = field('tw_2', 711, 1.0, 0.0, fine=0.0)
    g.open_flat = True
    for x, y in g.cells():
        g.H[y][x] = 1
        g.O[y][x] = 'W' if x in (0, 19) or y in (0, 17) else 's'
    for x in range(4, 17, 4):
        for y in (4, 13):
            g.O[y][x] = 'I'
    boss(g, 7, 8, '双子（左）')
    boss(g, 12, 8, '双子（右）')
    flatten_exits(g); return g

def make_tw_3():
    g = field('tw_3', 721, 0.0, 0.0, fine=0.0)
    g.open_flat = True
    cx, cy = 9.5, 8.5
    for x, y in g.cells():
        r = max(abs(x - cx), abs(y - cy))
        g.H[y][x] = -1
        if r < 2.6:
            g.H[y][x] = 0
            g.O[y][x] = 'W'   # 塔の芯
        elif r < 7.6:
            a = math.atan2(x - cx, -(y - cy))   # 北が0、時計回り
            if a < 0:
                a += 2 * math.pi
            frac = a / (1.8 * math.pi)
            if frac <= 1.0:
                g.H[y][x] = min(8, int(frac * 9))
                g.O[y][x] = 's'
    for x in range(8, 11):
        for y in range(0, 2):
            g.H[y][x] = 0
            g.O[y][x] = 's'
        for y in range(16, 18):
            g.H[y][x] = 4
            g.O[y][x] = 's'
    boss(g, 3, 4, 'らせん塔の番人')
    return g

def make_tw_4():
    g = field('tw_4', 731, 0.0, 0.0, fine=0.0)
    g.open_flat = True
    cx, cy = 9.5, 8.5
    for x, y in g.cells():
        d = math.hypot(x - cx, y - cy)
        if d < 7.6:
            g.H[y][x] = 8
            g.O[y][x] = 's'
            a = math.atan2(y - cy, x - cx)
            q = round(a / (math.pi / 4)) * (math.pi / 4)
            if 6.0 < d < 7.0 and abs(q - a) < 0.15:
                g.O[y][x] = 'I'
        else:
            g.H[y][x] = -1
    for y in range(0, 3):
        for x in range(8, 11):
            g.H[y][x] = 8
            g.O[y][x] = 's'
    boss(g, 9, 9, 'ブライト')
    return g

# ---------------------------------------------------------------- 寄り道のエリアと地方の印（2026-11-25 夜）
SEAL = {'山岳': 'seal_mt', '草原': 'seal_gr', '廃城': 'seal_cs', '溶岩': 'seal_lv'}

def seal(g):
    """地方の印を1つ置く。出口から遠く、高い所ほど選ばれる（探して登って取る）。仕掛けの奥には置かない。"""
    exits = [c for e in g.exits for c in exit_cells(g.name, *e[1:4])]
    taken = {(x, y) for x, y, _, _ in g.pickups}
    best, best_score = None, -1
    for x, y in g.cells():
        if not (2 <= x < g.w - 2 and 2 <= y < g.h - 2):
            continue
        if g.O[y][x] not in '.Fgs' or (x, y) in g.reserved or (x, y) in g.locked or (x, y) in taken or g.H[y][x] < 0:
            continue
        d = min(abs(x - ex) + abs(y - ey) for ex, ey in exits)
        score = d + g.H[y][x] * 2 + random.Random(g.seed * 7 + x * 31 + y).random()
        if score > best_score:
            best, best_score = (x, y), score
    pickup(g, best[0], best[1], SEAL[g.region], 1)
    g.reserved.add(best)

def side(name, seed, base, amp, mesa_n=3, fine=1.4, tilt=(0.0, 0.0), pre=None, after=None, enemies=5, loot_n=3):
    """寄り道のエリア：ふつうのエリアに、地方の印を1つ。敵は少し多い。"""
    def _after(g):
        if after:
            after(g)
        seal(g)
    return area(name, seed, base, amp, mesa_n=mesa_n, fine=fine, tilt=tilt, pre=pre, enemies=enemies, loot_n=loot_n, after=_after)

def make_mt_6():
    def _pre(g):
        river(g, [(4, 4), (9, 7), (15, 6), (19, 9)], '~', 0.9, gaps=(3, 12))
        pocket(g, 'CRACK', 13, 12, 15, 14, 'W', ('snow', 4))
        pocket(g, 'CRYSTAL', 17, 2, 19, 4, 'S', ('ether', 2))   # 水晶に魔法を当てると、足場がせり上がる
    return side('mt_6', 261, 2.0, 3.0, mesa_n=3, pre=_pre)

def make_mt_7():
    return side('mt_7', 271, 3.0, 3.5, mesa_n=3, tilt=(1.0, -1.0), enemies=4)

def make_mt_8():
    def _pre(g):
        pocket(g, 'VINES', 3, 3, 5, 5, 'E', ('potion_m', 2))
    return side('mt_8', 281, 2.5, 3.0, mesa_n=3, pre=_pre)

def make_gr_6():
    def _pre(g):
        river(g, [(2, 3), (8, 6), (13, 5), (20, 9)], '~', 0.9, gaps=(6, 17), bridge='=')
    def _after(g):
        grass_patches(g, 369, threshold=0.5)
    return side('gr_6', 361, 0.8, 2.2, mesa_n=2, pre=_pre, after=_after)

def make_gr_7():
    def _pre(g):
        pocket(g, 'THORNS', 11, 9, 13, 11, 'W', ('scale', 4))
    return side('gr_7', 371, 1.2, 2.6, mesa_n=3, pre=_pre, enemies=4)

def make_gr_8():
    def _pre(g):
        barrier(g, 4, 'THORNS', 9, '~')   # 西の帯の先が女王の巣（炎で茨を燃やす）
    def _after(g):
        grass_patches(g, 389, threshold=0.55, ch='F')
    return side('gr_8', 381, 1.0, 2.6, mesa_n=3, pre=_pre, after=_after, enemies=6, loot_n=4)

def make_gr_x():
    g = field('gr_x', 391, 1.0, 0.6, fine=0.5)
    g.open_flat = True
    for x, y in g.cells():
        d = math.hypot((x - 10) / 9.0, (y - 8) / 7.0)
        r = random.Random(x * 71 + y * 13).random()
        if d >= 1.0 and r < 0.6:
            g.O[y][x] = random.Random(x + y * 31).choice('TTBF')
        elif d < 1.0 and r < 0.25:
            g.O[y][x] = 'F'
    boss(g, 12, 7, '女王蜂')
    flatten_exits(g); loot(g, 392, 2, [('herb', 4), ('potion_m', 2)]); return g

def make_cs_6():
    def _pre(g):
        pocket(g, 'CRACK', 12, 3, 14, 5, 'S', ('silver', 3))
        pocket(g, 'CRYSTAL', 12, 10, 14, 12, 'W', ('money', 60))
    return side('cs_6', 461, 1.0, 2.4, mesa_n=2, fine=1.2, pre=_pre)

def make_cs_7():
    return side('cs_7', 471, 1.5, 3.0, mesa_n=3, enemies=4)

def make_cs_8():
    def _pre(g):
        barrier(g, 4, 'VINES', 6, '~')   # 西の帯の先が宝物庫（剣でつたを斬る）
    return side('cs_8', 481, 1.0, 2.0, mesa_n=2, pre=_pre, enemies=4)

def make_cs_x():
    g = field('cs_x', 491, 1.0, 0.3, fine=0.3)
    g.open_flat = True
    flatten(g, 1, 1, 16, 12, 1)
    for x in range(1, 17):
        for y in range(1, 13):
            g.O[y][x] = 's'
    for x, y in [(4, 3), (13, 3), (4, 10), (13, 10)]:
        g.O[y][x] = 'I'
    boss(g, 9, 6, '宝箱の王')
    flatten_exits(g); loot(g, 492, 2, [('money', 80), ('silver', 3)]); return g

def make_lv_6():
    def _pre(g):
        pocket(g, 'THORNS', 9, 3, 11, 5, 'S', ('obsidian', 3))
        pocket(g, 'BRITTLE', 11, 10, 13, 12, 'W', ('potion_l', 1))
    return side('lv_6', 561, 1.5, 2.6, mesa_n=2, pre=_pre)

def make_lv_7():
    def _pre(g):
        river(g, [(3, 2), (7, 7), (6, 12), (10, 15)], 'L', 0.6, gaps=(5, 14))
    return side('lv_7', 571, 2.0, 3.0, mesa_n=2, pre=_pre, enemies=4)

def make_lv_8():
    return side('lv_8', 581, 2.0, 3.0, mesa_n=3, enemies=5)

def make_tw_5():
    g = field('tw_5', 741, 1.5, 1.5, fine=0.8)
    mesas(g, 2, 742, rise=2, r=(2, 3))
    dress(g, 741)
    spawn(g, 744, 4)
    loot(g, 743, 3)
    return g

# ---------------------------------------------------------------- 霧の谷（2026-11-26 の4回目の直し）
# 主人公の村（灯りの村）があった谷。霧が濃く、枯れ木と暗い針葉樹。狼と黒騎士が出る。奥の砦に闇の王。
def make_mv_1():
    def _pre(g):
        river(g, [(0, 11), (6, 10), (12, 12), (17, 11), (21, 12)], '~', 0.7, gaps=(9, 30), bridge='=')
        pocket(g, 'CRACK', 16, 2, 18, 4, 'S', ('mist_moss', 3))
    return area('mv_1', 801, 1.5, 2.8, mesa_n=2, pre=_pre, enemies=5, loot_n=3)

def make_mv_2():
    """灯りの村跡（休憩所）：たき火の広場が村の真ん中。焼けた家の壁の残りと、村のお守り（闇の砦の門の鍵）。"""
    cx, cy, rx, ry = 8, 8, 4, 3
    def _pre(g):
        plaza(g, cx, cy, rx=rx, ry=ry)
        merchant(g, 10, 5, '霧の谷')
        for x, y in [(4, 5), (12, 5), (4, 11), (12, 11)]:
            g.O[y][x] = 'W'   # 焼けた家の壁の残り
            protect(g, [(x, y)])
        pickup(g, 5, 10, 'keepsake', 1)
    g = region_field('mv_2', 811, 2.0, 1.2, mesa_n=0, fine=1.0, pre=_pre)
    g.keep_pad = True
    carve_rest(g, cx, cy, rx, ry, keep_cells=[(x, y) for x in range(cx - rx - 1, cx + rx + 2) for y in range(cy - ry - 1, cy + ry + 2)])
    dress(g, 811)
    clear_void(g)
    loot(g, 813, 1)
    return g

def make_mv_3():
    def _pre(g):
        pocket(g, 'VINES', 11, 10, 13, 12, 'W', ('dark_shard', 2))
    def _after(g):
        scatter(g, [('k', 3), ('P', 4)], 0.10, 823)   # 森は木が多い
    return area('mv_3', 821, 2.0, 2.6, mesa_n=2, pre=_pre, after=_after, enemies=5, loot_n=3)

def make_mv_4():
    def _pre(g):
        pocket(g, 'BRITTLE', 27, 2, 29, 4, 'S', ('potion_l', 1))
        river(g, [(0, 9), (8, 8), (15, 10), (24, 9), (31, 10)], '~', 0.8, gaps=(12, 34, 52), bridge='=')
    def _after(g):
        ruins(g, 2, 836)   # 沈んだ街道ぞいの崩れた建物
    return area('mv_4', 831, 1.5, 2.4, mesa_n=3, pre=_pre, after=_after, enemies=6, loot_n=4)

def make_mv_5():
    """闇の砦：石の壁に囲まれた中庭。両側の城壁の上は高い通り道（階段で上がる）。"""
    g = field('mv_5', 841, 2.0, 0.5, fine=0.4)
    g.open_flat = True
    flatten(g, 1, 1, 22, 18, 2)
    for x in range(1, 23):
        for y in range(1, 19):
            edge = x in (1, 22) or y in (1, 18)
            if edge and not (y == 1 and 9 <= x <= 14):
                g.O[y][x] = 'W'
            elif x in (2, 3, 20, 21):
                g.H[y][x] = 5   # 城壁の上の通り道
                g.O[y][x] = 's'
            else:
                g.O[y][x] = 's'
    for y in (5, 9, 13):
        for x in (7, 16):
            g.O[y][x] = 'I'
    stair(g, [(6, 16), (5, 16), (4, 16), (3, 16)])
    stair(g, [(17, 16), (18, 16), (19, 16), (20, 16)])
    boss(g, 12, 10, '闇の王')
    flatten_exits(g); loot(g, 842, 2, [('dark_shard', 2), ('potion_m', 2)]); return g

def make_mv_6():
    def _pre(g):
        pocket(g, 'CRYSTAL', 11, 2, 13, 4, 'S', ('mist_moss', 4))
        for x, y in g.cells():
            if math.hypot((x - 9) / 3.2, (y - 10) / 2.4) < 1.0 and (x, y) not in g.reserved:
                g.O[y][x] = '~'   # 霧の湖
                g.reserved.add((x, y))
    return area('mv_6', 861, 1.5, 2.2, mesa_n=1, pre=_pre, enemies=4, loot_n=3)

EDGE = {'NORTH': 'ExitDef.Edge.NORTH', 'EAST': 'ExitDef.Edge.EAST', 'SOUTH': 'ExitDef.Edge.SOUTH', 'WEST': 'ExitDef.Edge.WEST'}
DIRS = {'RIGHT': 'Vector2.RIGHT', 'DOWN': 'Vector2.DOWN', 'LEFT': 'Vector2.LEFT', 'UP': 'Vector2.UP'}

def vec(c):
    return 'Vector2i(%d, %d)' % c

def write_gd(g):
    a = AREAS[g.name]
    L = ['extends RefCounted',
         '## %s のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。' % a['title'],
         '',
         'const ID := "%s"' % g.name,
         'const TITLE := "%s"' % a['title'],
         'const REGION := "%s"' % REGION[g.name],
         'const THEME := "%s"' % a['theme'],
         'const ORIGIN := Vector2i(%d, %d)' % a['origin'],
         '## 広場（たき火・町・ボスの間）。広い平地があってよい',
         'const OPEN_FLAT := %s' % ('true' if g.open_flat else 'false')]
    if g.start:
        L.append('const START := Vector2i(%d, %d)' % g.start)
    L.append('const HEIGHTS := [')
    L += ['\t"%s",' % ''.join('.' if v < 0 else str(v) for v in row) for row in g.H]
    L.append(']')
    L.append('const OBJECTS := [')
    L += ['\t"%s",' % ''.join(row) for row in g.O]
    L.append(']')
    L.append('## [辺, from, to, 相手, 門の id, この側から門を開けられるか]')
    L.append('const EXITS := [')
    for e in g.exits:
        L.append('\t[%s, %d, %d, "%s", "%s", %s],' % (EDGE[e[1]], e[2], e[3], e[4], e[5], 'true' if e[6] else 'false'))
    L.append(']')
    L.append('## [マス, 向き, 種類, レベル（倒したボスの数は足す前）]')
    L.append('const ENEMIES := [')
    for x, y, d, k, lv in g.enemies:
        L.append('\t[Vector2i(%d, %d), %s, EnemyKind.Kind.%s, %d],' % (x, y, DIRS[d], k, lv))
    L.append(']')
    L.append('## [マス, 品物の id（ItemCatalog、お金は money）, 数]')
    L.append('const PICKUPS := [')
    for x, y, k, n in g.pickups:
        L.append('\t[Vector2i(%d, %d), "%s", %d],' % (x, y, k, n))
    L.append(']')
    L.append('## 商人 [マス, お店の id（Shop.NAMES）]。前（南）に立って F でお店が開く')
    L.append('const MERCHANTS := [')
    for x, y, shop in g.merchants:
        L.append('\t[Vector2i(%d, %d), "%s"],' % (x, y, shop))
    L.append(']')
    L.append('## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]')
    L.append('const GIMMICKS := [')
    for gid, kind, cells, trig in g.gimmicks:
        extra = ', [%s]' % ', '.join(str(g.raise_to[c]) for c in cells) if kind == 'CRYSTAL' else ''
        L.append('\t["%s", "%s", [%s], [%s]%s],' % (gid, kind, ', '.join(vec(c) for c in cells), ', '.join(vec(c) for c in trig), extra))
    L.append(']')
    L.append('## ボスの居場所 [マス, 名前, 色]')
    L.append('const BOSSES := [')
    for x, y, name, tint in g.bosses:
        L.append('\t[Vector2i(%d, %d), "%s", Color("%s")],' % (x, y, name, tint))
    L.append(']')
    open(os.path.join(OUT, g.name + '.gd'), 'w', encoding='utf-8').write('\n'.join(L) + '\n')

def hub_of(g):
    if g.start:
        return g.start
    fire = getattr(g, 'campfire', None)
    if fire:
        return (fire[0], fire[1] + 1)
    for e in g.exits:
        c = exit_cells(g.name, *e[1:4])[0]
        if c not in g.locked:
            return c
    raise SystemExit('出発点がない: ' + g.name)

def finish(g):
    hub = hub_of(g)
    must = [c for e in g.exits for c in exit_cells(g.name, *e[1:4]) if c not in g.locked]
    must += [(x, y) for x, y, *_ in g.enemies] + [(x, y) for x, y, _, _ in g.pickups if (x, y) not in g.locked]
    must += g.must_extra
    connect(g, hub, must)
    fill_pockets(g, hub)
    connect(g, hub, must)
    flat = flats_ok(g, exempt=lambda x, y: g.open_flat or any(a <= x <= c and b <= y <= d for a, b, c, d in g.pads))
    if flat:
        print('  広い平地がある:', g.name, flat)
    check_unlocked(g, hub)
    return hub

def check_unlocked(g, hub):
    """仕掛けをすべて開けたとき、閉じていた所（宝・出口）へ行って帰れるか。"""
    if not g.gimmicks:
        return
    saved = [row[:] for row in g.O]
    saved_H = [row[:] for row in g.H]
    for _, kind, cells, _ in g.gimmicks:
        for x, y in cells:
            if kind == 'CRYSTAL':
                g.H[y][x] = g.raise_to[(x, y)]
            else:
                g.O[y][x] = '=' if kind == 'TARGET' else '.'
    fwd, back = bfs(g, hub), set(bfs(g, hub, reverse=True))
    locked_targets = [c for c in g.locked if g.O[c[1]][c[0]] not in BLOCK and walkable(g, *c)]
    bad = [c for c in locked_targets if c not in fwd or c not in back]
    g.O = saved
    g.H = saved_H
    if bad:
        raise SystemExit('仕掛けを開けても行けない: %s %s' % (g.name, bad[:5]))

# ---------------------------------------------------------------- 隠しもの
# 最初のカメラの向き（北が画面の上）では、すぐ手前（南）の崖か木の陰になって見えない宝箱。
# カメラを回すと見える。たどり着けるマスのうち、出口から離れていて、北側は開けている所を選ぶ。
HIDDEN = {'town': ('potion', 2), 'rocks': ('money', 30), 'hills': ('hide', 3), 'forest': ('potion', 2)}
HIDDEN_BY_THEME = {'mountain': ('iron_ore', 3), 'grass': ('potion', 2), 'castle': ('money', 40), 'lava': ('fire_stone', 3),
                   'tower': ('star_shard', 1), 'town': ('money', 30), 'mist': ('dark_shard', 2)}

def hidden_spots(g, hub):
    reach = bfs(g, hub)
    exits = [c for e in g.exits for c in exit_cells(g.name, *e[1:4])]
    taken = {(x, y) for x, y, _, _ in g.pickups} | {(x, y) for x, y, *_ in g.enemies}
    out = []
    for (x, y) in reach:
        if (x, y) in g.reserved or (x, y) in taken or g.O[y][x] not in '.s' or not g.inside(x, y + 1) or not g.inside(x, y - 1):
            continue
        if min(abs(x - ex) + abs(y - ey) for ex, ey in exits) < 6:
            continue
        h = g.H[y][x]
        front_h, front_o = g.H[y + 1][x], g.O[y + 1][x]
        cliff = front_h >= h + 2
        tree = front_o in 'TPWHRk' and front_h >= h
        back_open = g.O[y - 1][x] not in WALLS and g.H[y - 1][x] <= h + 1
        if (cliff or tree) and back_open:
            out.append((x, y))
    return sorted(out)

def place_hidden(g, hub):
    spots = hidden_spots(g, hub)
    if not spots:
        print('  隠しものを置く所がない:', g.name)
        return
    reach = bfs(g, hub)
    # 崖の陰を優先し、その中でたき火・入口から一番遠い所
    def score(c):
        x, y = c
        return (g.H[y + 1][x] >= g.H[y][x] + 2, reach[c])
    x, y = max(spots, key=score)
    kind, amount = HIDDEN.get(g.name) or HIDDEN_BY_THEME[g.theme]
    pickup(g, x, y, kind, amount)
    print('  隠しもの:', g.name, (x, y), kind, '崖' if g.H[y + 1][x] >= g.H[y][x] + 2 else '陰')

def dist(g, a, b):
    return bfs(g, a).get(b)

def preview(g, path):
    from PIL import Image
    S = 6
    im = Image.new('RGB', (g.w * S, g.h * S))
    col = {'T': (40, 110, 40), 'P': (25, 80, 45), 'B': (70, 130, 60), 'R': (140, 140, 135),
           '~': (70, 170, 200), '=': (150, 110, 70), '_': (0, 0, 0), 'C': (255, 140, 30), 'F': None,
           'L': (230, 80, 30), 'W': (120, 115, 110), 'I': (200, 195, 180), 'H': (180, 80, 60), 'O': (90, 120, 160),
           'M': (255, 220, 0), 'K': (255, 0, 255), 'Q': (255, 60, 60), 'X': (60, 40, 30), 'Y': (120, 40, 100), 'V': (0, 200, 60),
           'E': (90, 95, 110), 'N': (140, 100, 80), 'U': (255, 210, 120), 'J': (230, 70, 60), 'Z': (120, 200, 255),
           'k': (90, 80, 70)}
    for x, y in g.cells():
        hv = g.H[y][x]
        c = (60 + hv * 22, 110 + hv * 15, 50 + hv * 10) if hv >= 0 else (10, 10, 20)
        o = g.O[y][x]
        if col.get(o):
            c = col[o]
        for yy in range(S):
            for xx in range(S):
                im.putpixel((x * S + xx, y * S + yy), c)
    ecol = {'WEAK': (220, 40, 40), 'MELEE': (150, 60, 200), 'SHOOTER': (230, 170, 40), 'SHIELD': (90, 90, 220),
            'SHADOW': (30, 30, 30), 'FLYER': (200, 100, 200), 'CHARGER': (160, 90, 40), 'BOMBER': (255, 120, 0), 'GHOST': (220, 220, 255)}
    for x, y, _, k, _ in g.enemies:
        for yy in range(1, S - 1):
            for xx in range(1, S - 1):
                im.putpixel((x * S + xx, y * S + yy), ecol.get(k, (255, 0, 0)))
    for x, y, k, _ in g.pickups:
        for yy in range(2, S - 2):
            for xx in range(2, S - 2):
                im.putpixel((x * S + xx, y * S + yy), (255, 255, 255))
    im.save(path)

MAKERS = {
    'town': make_town, 'rocks': make_rocks, 'hills': make_hills, 'forest': make_forest,
    'mt_1': make_mt_1, 'mt_2': make_mt_2, 'mt_3': make_mt_3, 'mt_4': make_mt_4, 'mt_5': make_mt_5, 'mt_x': make_mt_x,
    'gr_1': make_gr_1, 'gr_2': make_gr_2, 'gr_3': make_gr_3, 'gr_4': make_gr_4, 'gr_5': make_gr_5,
    'cs_1': make_cs_1, 'cs_2': make_cs_2, 'cs_3': make_cs_3, 'cs_4': make_cs_4, 'cs_5': make_cs_5,
    'lv_1': make_lv_1, 'lv_2': make_lv_2, 'lv_3': make_lv_3, 'lv_4': make_lv_4, 'lv_5': make_lv_5, 'lv_x': make_lv_x,
    'tw_1': make_tw_1, 'tw_2': make_tw_2, 'tw_3': make_tw_3, 'tw_4': make_tw_4,
    'mt_6': make_mt_6, 'mt_7': make_mt_7, 'mt_8': make_mt_8,
    'gr_6': make_gr_6, 'gr_7': make_gr_7, 'gr_8': make_gr_8, 'gr_x': make_gr_x,
    'cs_6': make_cs_6, 'cs_7': make_cs_7, 'cs_8': make_cs_8, 'cs_x': make_cs_x,
    'lv_6': make_lv_6, 'lv_7': make_lv_7, 'lv_8': make_lv_8,
    'tw_5': make_tw_5,
    'mv_1': make_mv_1, 'mv_2': make_mv_2, 'mv_3': make_mv_3, 'mv_4': make_mv_4, 'mv_5': make_mv_5, 'mv_6': make_mv_6,
}

# ---------------------------------------------------------------- エリアを少し広く、形を四角でなく（2026-11-26 の3回目の直し）
# 作り終えたエリアを、大陸の列・行をところどころ2倍にして広げる（となりのエリアと同じ列・行なので、出口はずれない）。
# 段差は増えないので、つながりはそのまま。広がる割合はノイズで場所ごとに変わる（エリアごとにばらつく）。
GROW_SEED = 2611
UNIQUE_CH = set('CMKQOUJZ')   # 2倍にしない物（たき火・商人・像・的・井戸・押し板・レバー・水晶）。写しの側は何もない地面にする

def continent_bounds():
    xs = [a['origin'][0] for a in AREAS.values()] + [a['origin'][0] + a['size'][0] for a in AREAS.values()]
    ys = [a['origin'][1] for a in AREAS.values()] + [a['origin'][1] + a['size'][1] for a in AREAS.values()]
    return min(xs), max(xs), min(ys), max(ys)

def pick_dups(lo, hi, seed):
    n = value_noise(seed, 7.0)
    rng = random.Random(seed)
    return {c for c in range(lo, hi) if rng.random() < 0.08 + 0.30 * n(c, 0.5)}

def inflate_all(gs):
    x0, x1, y0, y1 = continent_bounds()
    DX, DY = pick_dups(x0, x1, GROW_SEED), pick_dups(y0, y1, GROW_SEED + 1)
    NX = lambda c: c + sum(1 for d in DX if d < c)
    NY = lambda c: c + sum(1 for d in DY if d < c)
    for name, g in gs.items():
        ox, oy = AREAS[name]['origin']
        xs = []   # 新しい列 → (元の列, 写しか)
        for x in range(g.w):
            xs.append((x, False))
            if ox + x in DX:
                xs.append((x, True))
        ys = []
        for y in range(g.h):
            ys.append((y, False))
            if oy + y in DY:
                ys.append((y, True))
        nx = lambda x: NX(ox + x) - NX(ox)
        ny = lambda y: NY(oy + y) - NY(oy)
        def copies(c):
            x, y = c
            out = []
            for xx in ([nx(x), nx(x) + 1] if ox + x in DX else [nx(x)]):
                for yy in ([ny(y), ny(y) + 1] if oy + y in DY else [ny(y)]):
                    out.append((xx, yy))
            return out
        first = lambda c: (nx(c[0]), ny(c[1]))
        g.H = [[g.H[y][x] for x, _ in xs] for y, _ in ys]
        g.O = [['.' if (cx or cy) and g.O[y][x] in UNIQUE_CH else g.O[y][x] for x, cx in xs] for y, cy in ys]
        g.w, g.h = len(xs), len(ys)
        g.enemies = [(*first((x, y)), *rest) for x, y, *rest in g.enemies]
        g.pickups = [(*first((x, y)), *rest) for x, y, *rest in g.pickups]
        g.merchants = [(*first((x, y)), *rest) for x, y, *rest in g.merchants]
        g.bosses = [(*first((x, y)), *rest) for x, y, *rest in g.bosses]
        g.gimmicks = [(gid, kind, [c2 for c in cells for c2 in copies(c)], [first(c) for c in trig]) for gid, kind, cells, trig in g.gimmicks]
        g.raise_to = {c2: h for c, h in g.raise_to.items() for c2 in copies(c)}
        g.reserved = {c2 for c in g.reserved for c2 in copies(c)}
        g.hedge = {c2 for c in g.hedge for c2 in copies(c)}
        g.locked = {c2 for c in g.locked for c2 in copies(c)}
        g.pads = [(nx(a), ny(b), copies((c, d))[-1][0], copies((c, d))[-1][1]) for a, b, c, d in g.pads]
        g.must_extra = [first(c) for c in g.must_extra]
        if g.start:
            g.start = first(g.start)
        if getattr(g, 'campfire', None):
            g.campfire = first(g.campfire)
    for name in AREAS:
        ox, oy = AREAS[name]['origin']
        g = gs[name]
        AREAS[name]['origin'] = (NX(ox), NY(oy))
        AREAS[name]['size'] = (g.w, g.h)
    global EXITS
    links = []
    for a, b, g0, g1, door, opener in LINKS:
        ax, ay = AREAS[a]['origin']; aw, ah = AREAS[a]['size']
        bx, by = AREAS[b]['origin']
        vertical = ax + aw == bx or bx + AREAS[b]['size'][0] == ax   # 東西の辺（範囲は y）
        D, N = (DY, NY) if vertical else (DX, NX)
        links.append((a, b, N(g0), N(g1) + (1 if g1 in D else 0), door, opener))
    EXITS = [e for l in links for e in _link_exits(*l)]
    for name, g in gs.items():
        g.exits = [e for e in EXITS if e[0] == name]
    print('  広げた：列 %d・行 %d' % (len(DX), len(DY)))

def roughen(g, hub):
    """ふちを島の外（深い谷）にして、形を四角でなくする。出口の道・物・仕掛け・広場のまわりは残す。
    つながりが切れたら、浅くしてやり直す（それでもだめなら何もしない）。"""
    keep = set(g.reserved) | set(g.locked) | set(g.hedge)
    def around(c, r):
        for dx in range(-r, r + 1):
            for dy in range(-r, r + 1):
                keep.add((c[0] + dx, c[1] + dy))
    for e in g.exits:
        cells = exit_cells(g.name, e[1], e[2], e[3])
        dx, dy = INWARD[e[1]]
        for c in cells:
            for k in range(7):
                around((c[0] + dx * k, c[1] + dy * k), 1)
    for x, y, *_ in g.enemies + g.pickups + g.merchants:
        around((x, y), 1)
    for x, y, *_ in g.bosses:
        around((x, y), 3)
    for _, _, cells, trig in g.gimmicks:
        for c in cells + trig:
            around(c, 2)
    for a, b, c, d in g.pads:
        for x in range(a - 1, c + 2):
            for y in range(b - 1, d + 2):
                keep.add((x, y))
    for c in g.must_extra:
        around(c, 1)
    around(hub, 2)
    n = value_noise(g.seed * 13 + 5, 3.2)
    m = value_noise(g.seed * 17 + 3, 9.0)
    saved_H = [row[:] for row in g.H]
    saved_O = [row[:] for row in g.O]
    must = [c for e in g.exits for c in exit_cells(g.name, *e[1:4]) if c not in g.locked]
    must += [(x, y) for x, y, *_ in g.enemies] + [(x, y) for x, y, _, _ in g.pickups if (x, y) not in g.locked]
    must += g.must_extra
    def connected():
        fwd, back = bfs(g, hub), set(bfs(g, hub, reverse=True))
        # 大事なマスへ行って帰れて、行けるのに戻れないくぼみもできない
        return all(c in fwd and c in back for c in must) and all(c in back for c in fwd)
    for scale in (1.0, 0.6):
        cand = []
        for x, y in g.cells():
            if (x, y) in keep or g.H[y][x] < 0:
                continue
            edge = min(x, y, g.w - 1 - x, g.h - 1 - y)
            if edge < scale * (0.3 + 2.6 * n(x, y) + 1.6 * m(x, y)):
                cand.append((edge, x, y))
        cand.sort()
        for _, x, y in cand:
            g.H[y][x] = -1
        if not connected():
            # まとめて削るとつながりが切れる：外側から1マスずつ、切れないものだけ削る
            for _, x, y in cand:
                g.H[y][x] = saved_H[y][x]
            for _, x, y in cand:
                g.H[y][x] = -1
                if not connected():
                    g.H[y][x] = saved_H[y][x]
        cut = 0
        for x, y in g.cells():
            if g.H[y][x] < 0 and saved_H[y][x] >= 0:
                g.O[y][x] = '.'
                cut += 1
        ok = True
        if g.gimmicks:
            try:
                check_unlocked(g, hub)
            except SystemExit:
                ok = False
        if ok:
            print('  形：%s ふちを %d マス削った' % (g.name, cut))
            return
        g.H = [row[:] for row in saved_H]
        g.O = [row[:] for row in saved_O]
    print('  形：%s は削れなかった' % g.name)

def recarve_rest(g, hub):
    """広げたあとの休憩所を、もう一度せまくする（2026-11-26）。たき火の広場と出口への道だけを残す。
    まっすぐの道が段差で切れるときは、行き来できるままの所だけを外側から1マスずつ削る。"""
    keep = [(x + i, y + j) for x, y, *_ in g.merchants for i in (-1, 0, 1) for j in (-1, 0, 1, 2)]
    keep += list(g.must_extra) + [(x, y) for x, y, *_ in g.pickups]
    if getattr(g, 'keep_pad', False):
        # 広場をまるごと残す（霧の谷の村跡。広場の四すみに焼けた家の壁）
        keep += [(x, y) for a, b, c, d in g.pads for x in range(a, c + 1) for y in range(b, d + 1)]
    saved_H = [row[:] for row in g.H]
    saved_O = [row[:] for row in g.O]
    must = []
    for e in g.exits:
        dx, dy = INWARD[e[1]]
        for x, y in exit_cells(g.name, *e[1:4]):
            if (x, y) not in g.locked:
                must += [(x, y), (x + dx, y + dy)]
    must += list(g.must_extra) + [(x, y) for x, y, _, _ in g.pickups if (x, y) not in g.locked]
    must = [c for c in must if walkable(g, *c)]
    def connected():
        fwd, back = bfs(g, hub), set(bfs(g, hub, reverse=True))
        return all(c in fwd and c in back for c in must) and all(c in back for c in fwd)
    kept = carve_rest(g, g.campfire[0], g.campfire[1], *g.rest_shape, keep_cells=keep)
    if not connected():
        g.H = [row[:] for row in saved_H]
        g.O = [row[:] for row in saved_O]
        fx, fy = g.campfire
        cand = sorted(((x, y) for x, y in g.cells() if (x, y) not in kept and g.H[y][x] >= 0),
                      key=lambda c: -math.hypot(c[0] - fx, c[1] - fy))
        for x, y in cand:
            g.H[y][x] = -1
            if not connected():
                g.H[y][x] = saved_H[y][x]
            else:
                g.O[y][x] = '.'
    clear_void(g)
    walk = sum(1 for x, y in g.cells() if walkable(g, x, y))
    print('  休憩所：%s 歩けるマス %d' % (g.name, walk))

def main():
    gs = {}
    for k, make in MAKERS.items():
        print(k)
        gs[k] = make()
    match_seams(gs)
    hubs = {}
    for k, g in gs.items():
        hubs[k] = finish(g)
    for k, g in gs.items():
        place_hidden(g, hubs[k])
    inflate_all(gs)
    for k, g in gs.items():
        hubs[k] = hub_of(g)
        if k != 'town' and not getattr(g, 'campfire', None):
            roughen(g, hubs[k])
        elif getattr(g, 'rest_shape', None):
            recarve_rest(g, hubs[k])
    for g in gs.values():
        write_gd(g)
        if '--preview' in sys.argv:
            preview(g, os.path.join(HERE, 'preview_%s.png' % g.name))
    print('wrote', OUT)

if __name__ == '__main__':
    main()
