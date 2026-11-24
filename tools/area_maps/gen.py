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
WALLS = set('TPBR')          # 通れない物
BLOCK = WALLS | set('~_')    # 通れないマス（水・奈落を含む）
CLIMB, DROP = 1, 3
SPEED_CELLS = 60.0 / 16.0    # プレイヤーの速さ（マス/秒）

# ---------------------------------------------------------------- 大陸の上の置き方
# 出口： (エリア, 辺, from, to, 相手, 門の id, この側から開けられるか)
AREAS = {
    'camp':   dict(title='野営地', origin=(0, 0),     size=(24, 20)),
    'rocks':  dict(title='岩場',   origin=(-40, -6),  size=(40, 32)),
    'hills':  dict(title='丘陵',   origin=(24, 0),    size=(48, 36)),
    'forest': dict(title='奥の森', origin=(8, -40),   size=(56, 40)),
}
EXITS = [
    ('camp', 'WEST', 8, 10, 'rocks', '', False),
    ('rocks', 'EAST', 14, 16, 'camp', '', False),
    ('camp', 'EAST', 8, 10, 'hills', '', False),
    ('hills', 'WEST', 8, 10, 'camp', '', False),
    ('hills', 'NORTH', 26, 28, 'forest', '', False),
    ('forest', 'SOUTH', 42, 44, 'hills', '', False),
    ('camp', 'NORTH', 10, 12, 'forest', 'forest_gate', False),
    ('forest', 'SOUTH', 2, 4, 'camp', 'forest_gate', True),
]

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
    return g.inside(x, y) and g.O[y][x] not in BLOCK

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
            if o in '~_' or n in g.hedge:
                continue  # 水・奈落・折り返しの生け垣は壊さない
            dh = abs(g.H[n[1]][n[0]] - g.H[c[1]][c[0]])
            cost = 1 + (8 if o in WALLS else 0) + 40 * max(0, dh - 1)
            nd = d + cost
            if nd < best.get(n, 1e9):
                best[n] = nd
                prev[n] = c
                heapq.heappush(pq, (nd, n))
    if goal is None:
        raise SystemExit('道を作れない: %s' % (src,))
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
        # 出口の両どなりのマスは木で縁取る（どこが出口かを分かりやすく）
        along = (1, 0) if e[1] in ('NORTH', 'SOUTH') else (0, 1)
        for x, y in ((cells[0][0] - along[0], cells[0][1] - along[1]), (cells[-1][0] + along[0], cells[-1][1] + along[1])):
            if g.inside(x, y) and (x, y) not in g.reserved:
                g.O[y][x] = 'P'

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
        print('  境目 %s-%s の高さ %d' % (e[0], e[4], h))

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

# ---------------------------------------------------------------- 書き出し
EDGE = {'NORTH': 'ExitDef.Edge.NORTH', 'EAST': 'ExitDef.Edge.EAST', 'SOUTH': 'ExitDef.Edge.SOUTH', 'WEST': 'ExitDef.Edge.WEST'}
DIRS = {'RIGHT': 'Vector2.RIGHT', 'DOWN': 'Vector2.DOWN', 'LEFT': 'Vector2.LEFT', 'UP': 'Vector2.UP'}

def write_gd(g):
    a = AREAS[g.name]
    L = ['extends RefCounted',
         '## %s のデータ。tools/area_maps/gen.py が作ったもの（手で直すときは gen.py を直して作り直す）。' % a['title'],
         '',
         'const ID := "%s"' % g.name,
         'const TITLE := "%s"' % a['title'],
         'const ORIGIN := Vector2i(%d, %d)' % a['origin']]
    if g.start:
        L.append('const START := Vector2i(%d, %d)' % g.start)
    L.append('const HEIGHTS := [')
    L += ['\t"%s",' % ''.join(str(v) for v in row) for row in g.H]
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
    open(os.path.join(OUT, g.name + '.gd'), 'w', encoding='utf-8').write('\n'.join(L) + '\n')

def finish(g):
    hub = g.start or exit_cells(g.name, *g.exits[0][1:4])[0]
    must = [c for e in g.exits for c in exit_cells(g.name, *e[1:4])]
    must += [(x, y) for x, y, _, _ in g.enemies] + [(x, y) for x, y, _, _ in g.pickups]
    connect(g, hub, must)
    fill_pockets(g, hub)
    connect(g, hub, must)
    flat = flats_ok(g, exempt=lambda x, y: g.name == 'camp' or any(a <= x <= c and b <= y <= d for a, b, c, d in g.pads))
    if flat:
        print('  広い平地がある:', g.name, flat)
    return hub

def dist(g, a, b):
    return bfs(g, a).get(b)

def preview(g, path):
    from PIL import Image
    S = 6
    im = Image.new('RGB', (g.w * S, g.h * S))
    col = {'T': (40, 110, 40), 'P': (25, 80, 45), 'B': (70, 130, 60), 'R': (140, 140, 135),
           '~': (70, 170, 200), '=': (150, 110, 70), '_': (0, 0, 0), 'C': (255, 140, 30), 'F': None}
    for x, y in g.cells():
        hv = g.H[y][x]
        c = (60 + hv * 22, 110 + hv * 15, 50 + hv * 10)
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

def main():
    gs = {'camp': make_camp(), 'rocks': make_rocks(), 'hills': make_hills(), 'forest': make_forest()}
    match_seams(gs)
    hubs = {k: finish(g) for k, g in gs.items()}
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
