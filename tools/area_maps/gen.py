# 大陸の4エリア（野営地・岩場・丘陵・奥の森）の地図を作り、scripts/areas/*.gd に書き出す。
# 使い方: python3 gen.py [--preview]   （--preview で preview_<id>.png も作る。Pillow が要る）
#
# 地形の作り方
# 1. ノイズで高さを作る（エリアごとの傾きと、細かい段差）。隣との差は1段までにならす。
# 2. 崖のある高台・台地を足す（ここだけ2段以上の差になる）。登り道（1段ずつの階段）をつける。
# 3. 木・岩・川の列で道を折り返させ、歩く距離をのばす（すき間を交互にあける）。
# 4. 出口の前は平らにし、敵1のいる所には6×6の平地を作る。
# 5. 行かなければならない所（出口・拾いもの・敵）がつながっているか確かめ、
#    落ちたら戻れないくぼみは茂みでふさぐ。
import math, os, random, sys
from collections import deque
import heapq

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'scripts', 'areas')
WALLS = set('TPBRWIHOMKQXYV')  # 通れない物（X・Y・V は仕掛けで、開けるまで通れない）
BLOCK = WALLS | set('~_L')    # 通れないマス（水・奈落・溶岩を含む）
CLIMB, DROP = 1, 3
SPEED_CELLS = 60.0 / 16.0    # プレイヤーの速さ（マス/秒）

# ---------------------------------------------------------------- 大陸の上の置き方
# エリア：id → 名前・地方（theme）・大陸の上の左上のマス・大きさ。
# 地方の並び（docs/superpowers/specs/2026-11-25-world-map-design.md 2章）：
# 真ん中に「はじまりの地」（野営地・岩場・丘陵・奥の森）、西に山岳、東に草原、北に廃城、南に町と溶岩、町の西に神秘の塔。
AREAS = {
    # はじまりの地
    'camp':   dict(title='野営地', theme='grass', origin=(0, 0),     size=(24, 20)),
    'rocks':  dict(title='岩場',   theme='grass', origin=(-40, -6),  size=(40, 32)),
    'hills':  dict(title='丘陵',   theme='grass', origin=(24, 0),    size=(48, 36)),
    'forest': dict(title='奥の森', theme='grass', origin=(8, -40),   size=(56, 40)),
    'town':   dict(title='町',     theme='town',  origin=(0, 20),    size=(24, 24)),
    # 山岳
    'mt_1': dict(title='山すそ',     theme='mountain', origin=(-88, -10),  size=(48, 40)),
    'mt_2': dict(title='山小屋',     theme='mountain', origin=(-80, -50),  size=(28, 40)),
    'mt_3': dict(title='岩の尾根',   theme='mountain', origin=(-128, -50), size=(48, 40)),
    'mt_4': dict(title='雪の峠',     theme='mountain', origin=(-128, -90), size=(76, 40)),
    'mt_5': dict(title='巨人の岩棚', theme='mountain', origin=(-120, -130), size=(48, 40)),
    'mt_x': dict(title='岩窟',       theme='mountain', origin=(-156, -40), size=(28, 24)),
    # 草原
    'gr_1': dict(title='草原の入口',   theme='grass', origin=(72, 4),   size=(48, 36)),
    'gr_2': dict(title='風見の休み場', theme='grass', origin=(120, 8),  size=(28, 24)),
    'gr_3': dict(title='花の丘',       theme='grass', origin=(120, -32), size=(48, 40)),
    'gr_4': dict(title='背高草の野',   theme='grass', origin=(148, 8),  size=(44, 40)),
    'gr_5': dict(title='大蛇の草むら', theme='grass', origin=(192, 12), size=(48, 40)),
    # 廃城
    'cs_1': dict(title='城下の跡',   theme='castle', origin=(16, -76),  size=(48, 36)),
    'cs_2': dict(title='崩れた兵舎', theme='castle', origin=(24, -112), size=(28, 36)),
    'cs_3': dict(title='城壁の道',   theme='castle', origin=(-24, -112), size=(48, 36)),
    'cs_4': dict(title='城の中庭',   theme='castle', origin=(-24, -148), size=(76, 36)),
    'cs_5': dict(title='王の間',     theme='castle', origin=(-8, -184), size=(48, 36)),
    # 溶岩
    'lv_1': dict(title='灰の道',         theme='lava', origin=(0, 44),   size=(28, 32)),
    'lv_2': dict(title='湯けむりの休み場', theme='lava', origin=(0, 76),   size=(28, 24)),
    'lv_3': dict(title='溶岩の川',       theme='lava', origin=(28, 76),  size=(44, 24)),
    'lv_4': dict(title='火口のふち',     theme='lava', origin=(0, 100),  size=(64, 36)),
    'lv_5': dict(title='満ち引きのくぼ地', theme='lava', origin=(8, 136), size=(48, 36)),
    'lv_x': dict(title='溶岩洞',         theme='lava', origin=(-28, 104), size=(28, 24)),
    # 神秘の塔
    'tw_1': dict(title='塔のふもと', theme='tower', origin=(-32, 26), size=(32, 28)),
    'tw_2': dict(title='塔の中',     theme='tower', origin=(-32, 54), size=(32, 32)),
    'tw_3': dict(title='塔の外周',   theme='tower', origin=(-64, 54), size=(32, 32)),
    'tw_4': dict(title='塔の最上階', theme='tower', origin=(-64, 86), size=(32, 24)),
}
REGION = {'camp': 'はじまりの地', 'rocks': 'はじまりの地', 'hills': 'はじまりの地', 'forest': 'はじまりの地', 'town': 'はじまりの地'}
for k in AREAS:
    if k not in REGION:
        REGION[k] = ({'mt': '山岳', 'gr': '草原', 'cs': '廃城', 'lv': '溶岩', 'tw': '神秘の塔'}[k[:2]])

# つながり：(エリアa, エリアb, 大陸の上のマスの範囲 g0〜g1, 門の id, 門を開けられる側)。
# 2つのエリアは辺を接していて、範囲はその辺に沿った大陸の座標（東西の辺なら y、南北の辺なら x）。
LINKS = [
    ('camp', 'rocks', 8, 10, '', None),
    ('camp', 'hills', 8, 10, '', None),
    ('hills', 'forest', 50, 52, '', None),
    ('camp', 'forest', 10, 12, 'forest_gate', 'forest'),
    ('camp', 'town', 10, 12, '', None),
    # 山岳
    ('rocks', 'mt_1', 14, 16, '', None),
    ('mt_1', 'mt_2', -68, -66, '', None),
    ('mt_2', 'mt_3', -24, -22, '', None),
    ('mt_3', 'mt_4', -110, -108, '', None),
    ('mt_4', 'mt_2', -68, -66, 'mt_gate', 'mt_4'),
    ('mt_4', 'mt_5', -100, -97, '', None),
    ('mt_3', 'mt_x', -30, -28, '', None),
    # 草原
    ('hills', 'gr_1', 18, 20, '', None),
    ('gr_1', 'gr_2', 18, 20, '', None),
    ('gr_2', 'gr_3', 132, 134, '', None),
    ('gr_3', 'gr_4', 156, 158, '', None),
    ('gr_4', 'gr_2', 20, 22, 'gr_gate', 'gr_4'),
    ('gr_4', 'gr_5', 28, 31, '', None),
    # 廃城
    ('forest', 'cs_1', 36, 38, '', None),
    ('cs_1', 'cs_2', 36, 38, '', None),
    ('cs_2', 'cs_3', -90, -88, '', None),
    ('cs_3', 'cs_4', -6, -4, '', None),
    ('cs_4', 'cs_2', 36, 38, 'cs_gate', 'cs_4'),
    ('cs_4', 'cs_5', 14, 17, '', None),
    # 溶岩
    ('town', 'lv_1', 10, 12, '', None),
    ('lv_1', 'lv_2', 8, 10, '', None),
    ('lv_2', 'lv_3', 86, 88, '', None),
    ('lv_3', 'lv_4', 50, 52, '', None),
    ('lv_4', 'lv_2', 12, 14, 'lv_gate', 'lv_4'),
    ('lv_4', 'lv_5', 30, 33, '', None),
    ('lv_4', 'lv_x', 116, 118, '', None),
    # 神秘の塔（町の西の封印の門。4体のボスを倒すと町の側から開けられる）
    ('town', 'tw_1', 32, 34, 'tower_seal', 'town'),
    ('tw_1', 'tw_2', -18, -16, '', None),
    ('tw_2', 'tw_3', 70, 72, '', None),
    ('tw_3', 'tw_4', -50, -48, '', None),
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
    g.bosses = []     # (x, y, 名前, 色)
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
        border = {'mountain': 'R', 'lava': 'R', 'castle': 'I', 'tower': 'I'}.get(getattr(g, 'theme', 'grass'), 'P')
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
    g.enemies.append((x, y, d, kind))
    g.reserved.add((x, y))
    g.O[y][x] = '.'

def pickup(g, x, y, kind, amount):
    g.pickups.append((x, y, kind, amount))
    g.reserved.add((x, y))
    g.O[y][x] = '.'

# ---------------------------------------------------------------- 野営地
def make_camp():
    g = new_area('camp', 3)
    n = value_noise(31, 5)
    for x, y in g.cells():
        g.H[y][x] = 1 + (1 if n(x, y) > 0.72 else 0)
    # 真ん中の広場（たき火）は平ら
    flatten(g, 6, 5, 17, 14, 1)
    g.O[10][12] = 'C'
    g.reserved |= {(x, y) for x in range(6, 18) for y in range(5, 15)}
    flatten_exits(g)
    # まわりを木で囲む（出口はあける）
    for x, y in g.cells():
        if (x in (0, 1, 22, 23) or y in (0, 1, 18, 19)) and (x, y) not in g.reserved:
            g.O[y][x] = g.rng.choice('TPTB')
    scatter(g, [('F', 3), ('T', 1), ('B', 1)], 0.10, 5)
    # 試すための武器の宝箱（本来はボスの落とし物。ボスができたら移す）
    pickup(g, 9, 8, 'SWORD', 1)
    pickup(g, 15, 8, 'BOW', 1)
    pickup(g, 15, 12, 'ARROWS', 50)
    pickup(g, 9, 12, 'POISON_ARROWS', 10)
    pickup(g, 12, 6, 'STAFF_FIRE', 3)
    pickup(g, 10, 6, 'STAFF_FIRE', 9)
    pickup(g, 14, 6, 'HEAL', 3)
    pickup(g, 8, 10, 'ARMOR', 1)
    g.start = (12, 11)
    return g

# ---------------------------------------------------------------- 岩場（行き止まり。素材と回復がある）
def make_rocks():
    g = new_area('rocks', 5)
    nb = value_noise(51, 11)
    noise_heights(g, lambda x, y: 1.0 + 4.0 * nb(x, y) + (x / 40.0) * 1.0, fine=1.8)
    # 崖で囲まれた高台（北西）。登り道は裏（西）にだけある
    cx, cy = 10, 9
    mesa = lambda x, y: math.hypot((x - cx) / 7.5, (y - cy) / 5.5) < 1.0
    top = max(g.H[y][x] for x, y in g.cells() if mesa(x, y))
    for x, y in g.cells():
        if mesa(x, y):
            g.H[y][x] = min(8, top + 2)
    stair(g, [(0, 15), (1, 14), (2, 13), (2, 12), (2, 11), (3, 10)])
    # 南の、崖の上の細い尾根
    for x in range(14, 30):
        for y in (24, 25):
            g.H[y][x] = min(8, g.H[y][x] + 2)
    stair(g, [(31, 26), (30, 25)])
    # 岩をたくさん
    scatter(g, [('R', 6), ('B', 2), ('P', 1)], 0.13, 7)
    flatten_exits(g)
    pad(g, 30, 8); enemy(g, 30, 8, 'WEAK', 'DOWN')
    pad(g, 20, 17); enemy(g, 20, 17, 'WEAK')
    pad(g, 9, 24); enemy(g, 9, 24, 'WEAK', 'DOWN')
    pad(g, 26, 29); enemy(g, 26, 29, 'WEAK')
    enemy(g, 16, 6, 'MELEE', 'DOWN')
    pickup(g, 10, 9, 'MATERIAL', 3)    # 高台の上
    pickup(g, 11, 8, 'HEAL', 1)
    pickup(g, 22, 24, 'MATERIAL', 2)   # 尾根の上
    pickup(g, 5, 28, 'MONEY', 20)
    pickup(g, 33, 4, 'MATERIAL', 1)
    pickup(g, 24, 13, 'MONEY', 10)
    pickup(g, 3, 2, 'HEAL', 1)
    g.start = None
    return g

# ---------------------------------------------------------------- 丘陵（川と生け垣で折り返す）
def river_x(y):
    return 19.5 + 1.8 * math.sin(y / 5.0)

def make_hills():
    g = new_area('hills', 9)
    nb = value_noise(91, 13)
    noise_heights(g, lambda x, y: 0.5 + 3.2 * (x / 48.0 + (35 - y) / 35.0) / 2 * 2 + 1.5 * nb(x, y), fine=1.5)
    # 東側の段々畑：生け垣の列ごとに1段ずつ高くする（列の上が段のふち）
    rows = [(27, 'W'), (20, 'E'), (13, 'W'), (6, 'E')]
    # 川（北から南へ）。橋は南の端だけ
    for y in range(g.h):
        rx = river_x(y)
        for x in range(g.w):
            if abs(x - rx) < 1.3:
                g.O[y][x] = '~'
                g.reserved.add((x, y))
    for x in range(g.w):
        if g.O[31][x] == '~':
            g.O[31][x] = '='
    # 生け垣の列（川の東の岸から東の端まで）。すき間を東と西に交互にあける
    for y, gap in rows:
        x0 = int(math.ceil(river_x(y) + 1.3))
        for x in range(x0, g.w):
            in_gap = (gap == 'E' and x >= g.w - 3) or (gap == 'W' and x < x0 + 3)
            if not in_gap:
                g.O[y][x] = 'T' if (x + y) % 3 else 'B'
                g.hedge.add((x, y))
            g.reserved.add((x, y))  # すき間にも木を置かない
    # 西の岸の木立
    scatter(g, [('T', 3), ('P', 1), ('B', 2), ('F', 3)], 0.10, 11,
            avoid=lambda x, y: x > river_x(y) - 2 and x < river_x(y) + 2)
    flatten_exits(g)
    pad(g, 8, 20); enemy(g, 8, 20, 'WEAK')
    pad(g, 8, 30); enemy(g, 8, 30, 'WEAK')
    pad(g, 35, 30); enemy(g, 35, 30, 'WEAK')
    pad(g, 34, 17); enemy(g, 34, 17, 'WEAK')
    pad(g, 40, 9); enemy(g, 40, 9, 'WEAK', 'DOWN')
    enemy(g, 30, 24, 'MELEE', 'DOWN')
    enemy(g, 30, 10, 'MELEE')
    pickup(g, 45, 33, 'MONEY', 20)
    pickup(g, 4, 33, 'MATERIAL', 2)
    pickup(g, 45, 16, 'HEAL', 1)
    pickup(g, 24, 3, 'MONEY', 10)
    pickup(g, 13, 4, 'MATERIAL', 1)
    g.start = None
    return g

# ---------------------------------------------------------------- 奥の森（高い台地と、門の近道）
PLATEAU_X = 18   # これより西が台地
GATE_ZONE_Y = 31 # これより南の西側は、門の前の低い所

def make_forest():
    g = new_area('forest', 13)
    nb = value_noise(131, 12)
    noise_heights(g, lambda x, y: 2.0 + 2.5 * nb(x, y) + (39 - y) / 39.0 * 1.5, fine=1.5)
    # 西の台地（崖で囲まれた高い所、6〜8段）。北東の階段からだけ登れる
    np_ = value_noise(137, 3.0)
    for x, y in g.cells():
        if x < PLATEAU_X and y < GATE_ZONE_Y:
            g.H[y][x] = 6 + int(2.6 * np_(x, y))
    relax(g, lambda x, y: x < PLATEAU_X and y < GATE_ZONE_Y)
    # 門の前の低い所（台地から3段飛び降りられる）
    for x, y in g.cells():
        if x < PLATEAU_X and y >= GATE_ZONE_Y:
            g.H[y][x] = 4
    # 台地のすぐ東は台地のふちより2段以上低くする（崖の下から登れないように）。下げた所からは、なだらかにならす
    for y in range(GATE_ZONE_Y):
        g.H[y][PLATEAU_X] = min(g.H[y][PLATEAU_X], g.H[y][PLATEAU_X - 1] - 2)
    relax(g, lambda x, y: x >= PLATEAU_X)
    # 台地の北東の階段（崖の下 → 台地）
    stair(g, [(PLATEAU_X + 6, 2), (PLATEAU_X + 5, 2), (PLATEAU_X + 4, 2), (PLATEAU_X + 3, 2),
              (PLATEAU_X + 2, 2), (PLATEAU_X + 1, 2), (PLATEAU_X, 2), (PLATEAU_X - 1, 2)])
    # 東の森：とがった木の列で折り返す
    rows = [(34, 'W'), (28, 'E'), (22, 'W'), (16, 'E'), (10, 'W')]
    for y, gap in rows:
        for x in range(PLATEAU_X, g.w):
            in_gap = (gap == 'E' and x >= g.w - 3) or (gap == 'W' and x < PLATEAU_X + 3)
            if not in_gap:
                g.O[y][x] = 'P' if (x + y) % 4 else 'T'
                g.hedge.add((x, y))
            g.reserved.add((x, y))  # すき間にも木を置かない
    # 奈落の裂け目（東の森の真ん中、細い道の横）
    for c in line_cells([(34, 19), (38, 20), (42, 18), (47, 19)], 0.6):
        if g.inside(*c):
            g.O[c[1]][c[0]] = '_'
            g.reserved.add(c)
    scatter(g, [('P', 4), ('T', 3), ('B', 1)], 0.16, 17)
    flatten_exits(g)
    enemy(g, 30, 36, 'MELEE')
    enemy(g, 45, 25, 'MELEE')
    enemy(g, 40, 13, 'MELEE', 'DOWN')
    enemy(g, 8, 12, 'MELEE', 'DOWN')
    pad(g, 34, 6, 2); enemy(g, 34, 6, 'SHOOTER')
    pad(g, 50, 13, 2); enemy(g, 50, 13, 'SHOOTER', 'DOWN')
    pickup(g, 5, 6, 'STRONG_BALL', 1)
    pickup(g, 12, 20, 'MATERIAL', 3)
    pickup(g, 52, 36, 'HEAL', 1)
    pickup(g, 26, 5, 'MATERIAL', 2)
    pickup(g, 46, 3, 'MONEY', 30)
    g.start = None
    return g

# ---------------------------------------------------------------- 地方のエリア（2026-11-25）
# 地方ごとの飾り（散らす物と割合）と、囲いに使う物
THEME_DECO = {
    'mountain': ([('R', 6), ('P', 2), ('B', 1)], 0.11),
    'grass':    ([('T', 2), ('B', 2), ('F', 3), ('g', 4)], 0.15),
    'lava':     ([('R', 5), ('B', 0)], 0.08),
    'castle':   ([('T', 1), ('B', 2), ('F', 2), ('I', 1)], 0.07),
    'tower':    ([('I', 1)], 0.015),
    'town':     ([('T', 2), ('F', 3), ('B', 1)], 0.08),
}
WALL_CH = {'mountain': 'R', 'grass': 'T', 'lava': 'R', 'castle': 'W', 'tower': 'W', 'town': 'T'}
# ボスの像の色
BOSS_TINT = {'岩転がしの巨人': '8d8f94', '草むらの大蛇': '6f9a5a', '満ち引きする溶岩': '7a4a3a', '廃城の主': '8a7f9a',
             '双子（左）': 'c9c3b6', '双子（右）': 'c9c3b6', 'らせん塔の番人': 'b8b2a4', 'ブライト': 'e8e2f0',
             '岩窟のぬし': '6a6c73', '溶岩洞のぬし': '9a3a2a'}

def field(name, seed, base, amp, fine=1.5, tilt=(0.0, 0.0), scale=11):
    g = new_area(name, seed)
    nb = value_noise(seed * 11 + 3, scale)
    noise_heights(g, lambda x, y: base + amp * nb(x, y) + tilt[0] * x / g.w + tilt[1] * y / g.h, fine=fine)
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
        w, h = rng.randint(5, 9), rng.randint(4, 7)
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
GIMMICK_CH = {'CRACK': 'X', 'THORNS': 'Y', 'VINES': 'V'}

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
    else:
        floor = A
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
    else:
        g.O[gate[1]][gate[0]] = GIMMICK_CH[kind]
        g.gimmicks.append((gid, kind, [gate], [gate]))
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

def statue(g, x, y, name):
    g.O[y][x] = 'K'
    protect(g, [(x, y)])
    g.bosses.append((x, y, name, BOSS_TINT.get(name, '9a968e')))
    front = (x, y + 1)
    g.O[front[1]][front[0]] = '.'
    g.H[front[1]][front[0]] = g.H[y][x]
    g.reserved.add(front)
    g.must_extra.append(front)

def merchant(g, x, y):
    g.O[y][x] = 'M'
    protect(g, [(x, y)])
    g.O[y + 1][x] = '.'
    g.reserved.add((x, y + 1))
    g.must_extra.append((x, y + 1))

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

def loot(g, seed, n, table):
    """拾いもの（お金・素材・回復）を、たどり着ける所にばらまく。"""
    rng = random.Random(seed)
    free = [(x, y) for x, y in g.cells() if g.O[y][x] in '.Fgs' and (x, y) not in g.reserved and g.H[y][x] >= 0]
    rng.shuffle(free)
    placed = []
    for c in free:
        if len(placed) >= n:
            break
        if all(abs(c[0] - p[0]) + abs(c[1] - p[1]) > 8 for p in placed):
            kind, amount = table[len(placed) % len(table)]
            pickup(g, c[0], c[1], kind, amount)
            placed.append(c)

LOOT = [('MONEY', 20), ('MATERIAL', 2), ('HEAL', 1), ('MONEY', 30), ('MATERIAL', 3)]

def region_field(name, seed, base, amp, mesa_n=3, fine=1.5, tilt=(0.0, 0.0), pre=None):
    g = field(name, seed, base, amp, fine=fine, tilt=tilt)
    if pre:
        pre(g)   # 仕掛け・たき火などを先に置く（高台がかぶらないように）
    if g.theme == 'mountain':
        mesas(g, mesa_n, seed + 1, rise=2, r=(3, 6))
    elif g.theme == 'castle':
        mesas(g, max(1, mesa_n - 1), seed + 1, rise=2, r=(3, 5))
    else:
        mesas(g, mesa_n, seed + 1, rise=2, r=(3, 5))
    return g

def dress(g, seed):
    """地方の飾りを足し、出口の前を平らにする。"""
    if g.theme == 'grass':
        grass_patches(g, seed + 5)
    if g.theme == 'castle':
        ruins(g, 4, seed + 6)
    scatter_theme(g, seed + 7)
    flatten_exits(g)

# ---- 山岳
def make_mt_1():
    def _pre_882(g):
        pocket(g, 'CRACK', 36, 6, 40, 9, 'S', ('MATERIAL', 4))
    g = region_field('mt_1', 201, 1.5, 4.5, mesa_n=4, pre=_pre_882)
    dress(g, 201); loot(g, 202, 4, LOOT); return g

def make_mt_2():
    def _pre_887(g):
        plaza(g, 14, 20)
    g = region_field('mt_2', 211, 3.0, 3.0, mesa_n=1, pre=_pre_887)
    dress(g, 211); loot(g, 212, 2, LOOT); return g

def make_mt_3():
    def _pre_892(g):
        barrier(g, 7, 'TARGET', 21, '~')
    g = region_field('mt_3', 221, 2.5, 4.5, mesa_n=4, pre=_pre_892)
    dress(g, 221); loot(g, 222, 4, LOOT); return g

def make_mt_4():
    def _pre_897(g):
        pocket(g, 'VINES', 44, 14, 48, 17, 'S', ('ARROWS', 30))
    g = region_field('mt_4', 231, 3.5, 4.0, mesa_n=6, tilt=(0.0, -1.5), pre=_pre_897)
    dress(g, 231); loot(g, 232, 6, LOOT); return g

def make_mt_5():
    g = field('mt_5', 241, 2.0, 2.0, fine=1.2)
    g.open_flat = True
    for x, y in g.cells():
        if 12 <= x <= 35 and 3 <= y <= 13:
            g.H[y][x] = 7   # 巨人の岩棚（まわりより3段以上高い）
        elif 12 <= x <= 35 and 14 <= y <= 15:
            g.H[y][x] = 3
    stair(g, [(11, 21), (11, 20), (11, 19), (11, 18), (11, 17), (11, 16), (11, 15), (11, 14), (11, 13), (12, 13)])
    for x in range(38, 46):
        for y in range(4, 18):
            g.H[y][x] = 8   # 東の尾根（岩棚を見下ろせる）
    stair(g, [(41, 26), (41, 25), (41, 24), (41, 23), (41, 22), (41, 21), (41, 20), (41, 19), (41, 18), (41, 17)])
    statue(g, 24, 7, '岩転がしの巨人')
    protect(g, [(x, y) for x in range(12, 36) for y in range(3, 14)])
    for x, y in g.cells():
        if (x, y) not in g.reserved and g.O[y][x] == '.' and random.Random(x * 99 + y).random() < 0.06:
            g.O[y][x] = 'R'
    flatten_exits(g); loot(g, 242, 2, LOOT); return g

def make_mt_x():
    g = field('mt_x', 251, 2.0, 1.5, fine=1.0)
    g.open_flat = True
    for x, y in g.cells():
        if math.hypot((x - 12) / 11.0, (y - 11.5) / 9.5) > 1.0:
            g.O[y][x] = 'R'
    statue(g, 8, 11, '岩窟のぬし')
    flatten_exits(g); loot(g, 252, 2, [('MATERIAL', 5), ('MONEY', 50)]); return g

# ---- 草原
def make_gr_1():
    def _pre(g):
        pocket(g, 'CRACK', 6, 24, 10, 28, 'N', ('MONEY', 40))
        river(g, [(30, 0), (28, 12), (31, 24), (29, 35)], '~', 0.7, gaps=(9, 40), bridge='=')
    g = region_field('gr_1', 301, 0.8, 2.6, mesa_n=3, fine=1.3, pre=_pre)
    dress(g, 301); loot(g, 302, 4, LOOT); return g

def make_gr_2():
    def _pre_938(g):
        plaza(g, 14, 12)
        merchant(g, 17, 9)
    g = region_field('gr_2', 311, 1.0, 1.5, mesa_n=1, fine=1.0, pre=_pre_938)
    dress(g, 311); loot(g, 312, 2, LOOT); return g

def make_gr_3():
    def _pre_944(g):
        pocket(g, 'THORNS', 30, 6, 34, 9, 'S', ('HEAL', 3))
    g = region_field('gr_3', 321, 1.2, 3.0, mesa_n=4, fine=1.4, pre=_pre_944)
    dress(g, 321)
    grass_patches(g, 329, threshold=0.55, ch='F')
    loot(g, 322, 4, LOOT); return g

def make_gr_4():
    def _pre_951(g):
        pocket(g, 'TARGET', 30, 28, 34, 31, 'N', ('ARROWS', 40))
    g = region_field('gr_4', 331, 1.0, 2.4, mesa_n=3, fine=1.3, pre=_pre_951)
    dress(g, 331)
    grass_patches(g, 338, threshold=0.5)
    loot(g, 332, 4, LOOT); return g

def make_gr_5():
    g = field('gr_5', 341, 0.8, 1.6, fine=1.0, scale=14)
    g.open_flat = True
    statue(g, 24, 20, '草むらの大蛇')
    for x, y in g.cells():
        if (x, y) in g.reserved or g.O[y][x] != '.':
            continue
        d = math.hypot((x - 24) / 20.0, (y - 20) / 16.0)
        r = random.Random(x * 131 + y * 7).random()
        if d < 1.0 and r < 0.75:
            g.O[y][x] = 'g'
        elif d >= 1.0 and r < 0.25:
            g.O[y][x] = random.Random(x + y * 57).choice('TBTF')
    flatten_exits(g); loot(g, 342, 2, LOOT); return g

# ---- 廃城
def make_cs_1():
    def _pre_974(g):
        pocket(g, 'VINES', 36, 14, 40, 17, 'W', ('MATERIAL', 4))
    g = region_field('cs_1', 401, 1.0, 2.5, mesa_n=3, fine=1.3, pre=_pre_974)
    dress(g, 401); loot(g, 402, 4, LOOT); return g

def make_cs_2():
    def _pre_979(g):
        plaza(g, 14, 17, paving=True)
        merchant(g, 17, 14)
    g = region_field('cs_2', 411, 1.5, 2.0, mesa_n=2, fine=1.2, pre=_pre_979)
    dress(g, 411); loot(g, 412, 2, LOOT); return g

def make_cs_3():
    def _pre_985(g):
        pocket(g, 'CRACK', 6, 6, 10, 9, 'S', ('MONEY', 50))
    g = region_field('cs_3', 421, 1.5, 3.0, mesa_n=3, fine=1.4, pre=_pre_985)
    dress(g, 421); loot(g, 422, 4, LOOT); return g

def make_cs_4():
    def _pre_990(g):
        pocket(g, 'THORNS', 64, 6, 68, 9, 'S', ('HEAL', 3))
    g = region_field('cs_4', 431, 1.5, 3.0, mesa_n=4, fine=1.4, pre=_pre_990)
    dress(g, 431); loot(g, 432, 6, LOOT); return g

def make_cs_5():
    g = field('cs_5', 441, 1.0, 0.5, fine=0.4)
    g.open_flat = True
    h = flatten(g, 3, 2, 44, 33, 1)
    for x in range(3, 45):
        for y in range(2, 34):
            edge = x in (3, 44) or y in (2, 33)
            if edge and not (y == 33 and 21 <= x <= 26):
                g.O[y][x] = 'W'
            elif x in (4, 5, 42, 43) or y in (3, 4):
                g.H[y][x] = 3   # 崩れた壁の上（高い通り道）
                g.O[y][x] = '.'
            else:
                g.O[y][x] = 's'
    for y in range(8, 30, 4):
        for x in (12, 35):
            g.O[y][x] = 'I'
    stair(g, [(9, 30), (8, 30), (7, 30), (6, 30), (5, 30)])
    stair(g, [(38, 30), (39, 30), (40, 30), (41, 30), (42, 30)])
    for y in range(31, 33):
        for x in range(4, 44):
            if g.O[y][x] == 's' and g.H[y][x] > 1:
                g.H[y][x] = 1
    statue(g, 24, 7, '廃城の主')
    g.O[8][24] = 's'
    flatten_exits(g); loot(g, 442, 2, LOOT); return g

# ---- 溶岩
def make_lv_1():
    def _pre(g):
        pocket(g, 'CRACK', 19, 4, 23, 7, 'W', ('MATERIAL', 3))
        river(g, [(0, 16), (9, 14), (18, 18), (27, 15)], 'L', 0.7, gaps=(6, 24))
    g = region_field('lv_1', 501, 1.5, 3.0, mesa_n=2, fine=1.4, pre=_pre)
    dress(g, 501); loot(g, 502, 3, LOOT); return g

def make_lv_2():
    def _pre_1029(g):
        plaza(g, 14, 11)
    g = region_field('lv_2', 511, 2.0, 1.5, mesa_n=1, fine=1.0, pre=_pre_1029)
    dress(g, 511); loot(g, 512, 2, LOOT); return g

def make_lv_3():
    def _pre(g):
        pocket(g, 'THORNS', 36, 4, 40, 7, 'S', ('HEAL', 2))
        river(g, [(10, 0), (14, 9), (12, 16), (16, 23)], 'L', 0.7, gaps=(5, 18))
        river(g, [(30, 0), (27, 8), (31, 15), (28, 23)], 'L', 0.7, gaps=(8, 20))
    g = region_field('lv_3', 521, 1.5, 3.0, mesa_n=2, fine=1.4, pre=_pre)
    dress(g, 521); loot(g, 522, 3, LOOT); return g

def make_lv_4():
    def _pre_1041(g):
        barrier(g, 6, 'VINES', 17, 'L')
    g = region_field('lv_4', 531, 2.0, 3.5, mesa_n=4, fine=1.5, pre=_pre_1041)
    river(g, [(20, 10), (34, 14), (46, 9), (58, 13)], 'L', 0.7, gaps=(4, 22, 40))
    dress(g, 531); loot(g, 532, 5, LOOT); return g

def make_lv_5():
    g = field('lv_5', 541, 4.0, 1.0, fine=0.6)
    g.open_flat = True
    rng = random.Random(545)
    for x, y in g.cells():
        d = math.hypot((x - 24) / 19.0, (y - 18) / 14.0)
        if d < 1.0:
            g.H[y][x] = 1
            if 0.55 < d < 0.75:
                g.O[y][x] = 'L'   # 低い所を囲む溶岩の輪（ボスで満ち引きする所）
    for k, (ix, iy) in enumerate([(14, 12), (34, 12), (14, 25), (34, 25)]):
        for x, y in g.cells():
            if math.hypot(x - ix, y - iy) < 2.6:
                g.H[y][x] = 3 + k % 2
                g.O[y][x] = '.'
    # 溶岩の輪をまたぐ道（北・南・西・東）
    for (x0, y0, x1, y1) in [(23, 2, 25, 9), (23, 27, 25, 34), (5, 17, 13, 19), (35, 17, 43, 19)]:
        for x in range(x0, x1 + 1):
            for y in range(y0, y1 + 1):
                if g.O[y][x] == 'L':
                    g.O[y][x] = '.'
    relax(g)
    for x, y in g.cells():
        if math.hypot(x - 24, y - 18) < 3.2:
            g.H[y][x] = 3
    statue(g, 24, 17, '満ち引きする溶岩')
    flatten_exits(g); loot(g, 542, 2, LOOT); return g

def make_lv_x():
    g = field('lv_x', 551, 2.0, 1.0, fine=0.8)
    g.open_flat = True
    for x, y in g.cells():
        if math.hypot((x - 13) / 12.0, (y - 12) / 10.5) > 1.0:
            g.O[y][x] = 'R'
        elif math.hypot(x - 15, y - 6) < 2.5 or math.hypot(x - 16, y - 18) < 2.2:
            g.O[y][x] = 'L'
    statue(g, 8, 12, '溶岩洞のぬし')
    flatten_exits(g); loot(g, 552, 2, [('MATERIAL', 5), ('HEAL', 3)]); return g

# ---- 町
def make_town():
    g = new_area('town', 601)
    n = value_noise(611, 5)
    for x, y in g.cells():
        g.H[y][x] = 1 + (1 if n(x, y) > 0.75 else 0)
    plaza(g, 12, 12, rx=7, ry=5, paving=True)
    for (x0, y0, x1, y1) in [(2, 2, 6, 5), (15, 2, 20, 5), (2, 18, 6, 21), (16, 18, 21, 21)]:
        flatten(g, x0 - 1, y0 - 1, x1 + 1, y1 + 1, 1)
        for x in range(x0, x1 + 1):
            for y in range(y0, y1 + 1):
                g.O[y][x] = 'H'
        protect(g, [(x, y) for x in range(x0 - 1, x1 + 2) for y in range(y0 - 1, y1 + 2)])
        for x in range(x0 - 1, x1 + 2):
            for y in range(y0 - 1, y1 + 2):
                if g.O[y][x] != 'H':
                    g.O[y][x] = '.'
    g.O[9][8] = 'O'
    protect(g, [(8, 9)])
    merchant(g, 16, 9)    # 道具屋
    merchant(g, 7, 14)    # 武器屋
    flatten_exits(g)
    for x, y in g.cells():
        if (x in (0, 23) or y in (0, 23)) and (x, y) not in g.reserved:
            g.O[y][x] = g.rng.choice('TPTB')
    scatter_theme(g, 607, avoid=lambda x, y: g.O[y][x] == 's')
    return g

# ---- 神秘の塔
def make_tw_1():
    g = field('tw_1', 701, 1.0, 1.0, fine=0.6)
    plaza(g, 16, 13, rx=6, ry=4, paving=True)
    for x in range(2, 30, 4):
        g.O[2][x] = 'I'
    for x, y in g.cells():
        if y >= 22 and (x < 11 or x > 20):
            g.O[y][x] = 'W'   # 塔の土台
    dress(g, 701); return g

def make_tw_2():
    g = field('tw_2', 711, 1.0, 0.0, fine=0.0)
    g.open_flat = True
    for x, y in g.cells():
        g.H[y][x] = 1
        g.O[y][x] = 'W' if x in (0, 31) or y in (0, 31) else 's'
    for x in range(5, 28, 5):
        for y in (6, 24):
            g.O[y][x] = 'I'
    statue(g, 11, 14, '双子（左）')
    statue(g, 20, 14, '双子（右）')
    flatten_exits(g); return g

def make_tw_3():
    g = field('tw_3', 721, 0.0, 0.0, fine=0.0)
    g.open_flat = True
    cx, cy = 15.5, 15.5
    for x, y in g.cells():
        r = max(abs(x - cx), abs(y - cy))
        g.H[y][x] = -1
        if r < 4:
            g.H[y][x] = 0
            g.O[y][x] = 'W'   # 塔の芯
        elif r < 9:
            a = math.atan2(-(y - cy), x - cx)   # 東が0、北が正（反時計回り）
            if a < 0:
                a += 2 * math.pi
            frac = a / (1.5 * math.pi)            # 東→北→西→南で 0→1
            if frac <= 1.0:
                g.H[y][x] = min(8, int(frac * 9))
                g.O[y][x] = 's'
    for x in range(24, 32):
        for y in range(16, 19):
            g.H[y][x] = 0
            g.O[y][x] = 's'
    for y in range(24, 32):
        for x in range(14, 17):
            g.H[y][x] = 8
            g.O[y][x] = 's'
    statue(g, 7, 15, 'らせん塔の番人')
    g.O[16][7] = 's'
    return g

def make_tw_4():
    g = field('tw_4', 731, 0.0, 0.0, fine=0.0)
    g.open_flat = True
    cx, cy = 15.5, 13.5
    for x, y in g.cells():
        d = math.hypot(x - cx, y - cy)
        if d < 10.5:
            g.H[y][x] = 8
            g.O[y][x] = 's'
            a = math.atan2(y - cy, x - cx)
            if 8.0 < d < 9.2 and int(round(a / (math.pi / 4))) * (math.pi / 4) - a < 0.12 and abs(int(round(a / (math.pi / 4))) * (math.pi / 4) - a) < 0.12:
                g.O[y][x] = 'I'
        else:
            g.H[y][x] = -1
    for y in range(0, 4):
        for x in range(14, 17):
            g.H[y][x] = 8
            g.O[y][x] = 's'
    statue(g, 15, 13, 'ブライト')
    return g

# ---------------------------------------------------------------- 書き出し
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
         'const OPEN_FLAT := %s' % ('true' if g.open_flat or g.name == 'camp' else 'false')]
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
    L.append('const ENEMIES := [')
    for x, y, d, k in g.enemies:
        L.append('\t[Vector2i(%d, %d), %s, EnemyKind.Kind.%s],' % (x, y, DIRS[d], k))
    L.append(']')
    L.append('const PICKUPS := [')
    for x, y, k, n in g.pickups:
        L.append('\t[Vector2i(%d, %d), RunState.PickupKind.%s, %d],' % (x, y, k, n))
    L.append(']')
    L.append('## 武器で開く仕掛け [id, 種類, ふさぐマス（的なら橋になる水のマス）, 武器を当てるマス]')
    L.append('const GIMMICKS := [')
    for gid, kind, cells, trig in g.gimmicks:
        L.append('\t["%s", "%s", [%s], [%s]],' % (gid, kind, ', '.join(vec(c) for c in cells), ', '.join(vec(c) for c in trig)))
    L.append(']')
    L.append('## ボスの居場所 [像のマス, 名前, 像の色]（ボスはまだいないので像を置く）')
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
    must += [(x, y) for x, y, _, _ in g.enemies] + [(x, y) for x, y, _, _ in g.pickups if (x, y) not in g.locked]
    must += g.must_extra
    connect(g, hub, must)
    fill_pockets(g, hub)
    connect(g, hub, must)
    flat = flats_ok(g, exempt=lambda x, y: g.open_flat or g.name == 'camp' or any(a <= x <= c and b <= y <= d for a, b, c, d in g.pads))
    if flat:
        print('  広い平地がある:', g.name, flat)
    check_unlocked(g, hub)
    return hub

def check_unlocked(g, hub):
    """仕掛けをすべて開けたとき、閉じていた所（宝・出口）へ行って帰れるか。"""
    if not g.gimmicks:
        return
    saved = [row[:] for row in g.O]
    for _, kind, cells, _ in g.gimmicks:
        for x, y in cells:
            g.O[y][x] = '=' if kind == 'TARGET' else '.'
    fwd, back = bfs(g, hub), set(bfs(g, hub, reverse=True))
    locked_targets = [c for c in g.locked if g.O[c[1]][c[0]] not in BLOCK and walkable(g, *c)]
    bad = [c for c in locked_targets if c not in fwd or c not in back]
    g.O = saved
    if bad:
        raise SystemExit('仕掛けを開けても行けない: %s %s' % (g.name, bad[:5]))

# ---------------------------------------------------------------- 隠しもの
# 最初のカメラの向き（北が画面の上）では、すぐ手前（南）の崖か木の陰になって見えない宝箱。
# カメラを回すと見える。たどり着けるマスのうち、出口から離れていて、北側は開けている所を選ぶ。
HIDDEN = {'camp': ('HEAL', 2), 'rocks': ('MONEY', 30), 'hills': ('MATERIAL', 3), 'forest': ('HEAL', 2)}
HIDDEN_BY_THEME = {'mountain': ('MATERIAL', 3), 'grass': ('HEAL', 2), 'castle': ('MONEY', 40), 'lava': ('MATERIAL', 3),
                   'tower': ('HEAL', 3), 'town': ('MONEY', 30)}

def hidden_spots(g, hub):
    reach = bfs(g, hub)
    exits = [c for e in g.exits for c in exit_cells(g.name, *e[1:4])]
    taken = {(x, y) for x, y, _, _ in g.pickups} | {(x, y) for x, y, _, _ in g.enemies}
    out = []
    for (x, y) in reach:
        if (x, y) in g.reserved or (x, y) in taken or g.O[y][x] not in '.s' or not g.inside(x, y + 1) or not g.inside(x, y - 1):
            continue
        if min(abs(x - ex) + abs(y - ey) for ex, ey in exits) < 6:
            continue
        h = g.H[y][x]
        front_h, front_o = g.H[y + 1][x], g.O[y + 1][x]
        cliff = front_h >= h + 2
        tree = front_o in 'TPWHR' and front_h >= h
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
           'M': (255, 220, 0), 'K': (255, 0, 255), 'Q': (255, 60, 60), 'X': (60, 40, 30), 'Y': (120, 40, 100), 'V': (0, 200, 60)}
    for x, y in g.cells():
        hv = g.H[y][x]
        c = (60 + hv * 22, 110 + hv * 15, 50 + hv * 10) if hv >= 0 else (10, 10, 20)
        o = g.O[y][x]
        if col.get(o):
            c = col[o]
        for yy in range(S):
            for xx in range(S):
                im.putpixel((x * S + xx, y * S + yy), c)
    for x, y, _, k in g.enemies:
        for yy in range(1, S - 1):
            for xx in range(1, S - 1):
                im.putpixel((x * S + xx, y * S + yy), (220, 40, 40) if k == 'WEAK' else (150, 60, 200) if k == 'MELEE' else (230, 170, 40))
    for x, y, k, _ in g.pickups:
        for yy in range(2, S - 2):
            for xx in range(2, S - 2):
                im.putpixel((x * S + xx, y * S + yy), (255, 255, 255))
    im.save(path)

MAKERS = {
    'camp': make_camp, 'rocks': make_rocks, 'hills': make_hills, 'forest': make_forest, 'town': make_town,
    'mt_1': make_mt_1, 'mt_2': make_mt_2, 'mt_3': make_mt_3, 'mt_4': make_mt_4, 'mt_5': make_mt_5, 'mt_x': make_mt_x,
    'gr_1': make_gr_1, 'gr_2': make_gr_2, 'gr_3': make_gr_3, 'gr_4': make_gr_4, 'gr_5': make_gr_5,
    'cs_1': make_cs_1, 'cs_2': make_cs_2, 'cs_3': make_cs_3, 'cs_4': make_cs_4, 'cs_5': make_cs_5,
    'lv_1': make_lv_1, 'lv_2': make_lv_2, 'lv_3': make_lv_3, 'lv_4': make_lv_4, 'lv_5': make_lv_5, 'lv_x': make_lv_x,
    'tw_1': make_tw_1, 'tw_2': make_tw_2, 'tw_3': make_tw_3, 'tw_4': make_tw_4,
}

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
    camp, hills, forest = gs['camp'], gs['hills'], gs['forest']
    # 経路の長さ（マス）：たき火 → 丘陵 → 奥の森の強い鉄球
    def mid_exit(area, edge, a, b, inward=1):
        c = exit_cells(area, edge, a, b)[(b - a) // 2]
        dx, dy = INWARD[edge]
        return (c[0] + dx * inward, c[1] + dy * inward)
    ball = next((x, y) for x, y, k, _ in forest.pickups if k == 'STRONG_BALL')
    d1 = dist(camp, camp.start, mid_exit('camp', 'EAST', 8, 10, 0))
    d2 = dist(hills, mid_exit('hills', 'WEST', 8, 10), mid_exit('hills', 'NORTH', 26, 28, 0))
    d3 = dist(forest, mid_exit('forest', 'SOUTH', 42, 44), ball)
    go = (d1 or 0) + (d2 or 0) + (d3 or 0)
    r1 = dist(forest, ball, mid_exit('forest', 'SOUTH', 2, 4, 0))
    r2 = dist(camp, mid_exit('camp', 'NORTH', 10, 12), camp.start)
    back = (r1 or 0) + (r2 or 0)
    print('行き: たき火→丘陵 %s + 丘陵 %s + 森→強い鉄球 %s = %d マス（%.0f秒、目安90秒以上）' % (d1, d2, d3, go, go / SPEED_CELLS))
    print('帰り: 強い鉄球→門 %s + 野営地 %s = %d マス（%.0f秒、目安30秒以内）' % (r1, r2, back, back / SPEED_CELLS))
    for g in gs.values():
        write_gd(g)
        if '--preview' in sys.argv:
            preview(g, os.path.join(HERE, 'preview_%s.png' % g.name))
    print('wrote', OUT)

if __name__ == '__main__':
    main()
