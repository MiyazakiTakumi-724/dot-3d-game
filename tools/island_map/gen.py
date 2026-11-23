# 箱庭の島の地図を作る（高さの層と物の層）。出力: heights.txt, objects.txt
import math, random
W, H = 100, 70
CX, CY = 50, 35
A, B = 46, 31
rng = random.Random(11)

def polar(x, y):
    dx = (x + 0.5 - CX) / A
    dy = (y + 0.5 - CY) / B
    return math.hypot(dx, dy), math.degrees(math.atan2(dy, dx))

def edge_r(th):
    t = math.radians(th)
    return 0.97 + 0.05 * math.sin(3 * t + 0.7) + 0.035 * math.sin(5 * t + 2.1) + 0.025 * math.sin(9 * t + 0.3)

def massif_r(th):
    t = math.radians(th)
    return 0.40 + 0.03 * math.sin(4 * t + 1.0) + 0.02 * math.sin(7 * t + 0.4)

hgt = [[None] * W for _ in range(H)]
obj = [['.'] * W for _ in range(H)]

def inside(x, y):
    return 0 <= x < W and 0 <= y < H

WALL_Y = 41  # 西の岩の壁（41・42行）。北が西の小道、南がたき火の草地

def ring_height(x, y, r, th):
    if x < CX and y >= WALL_Y:
        return 1  # 南西の草地
    th2 = th + 6 * math.sin(r * 9)  # 境目を少し曲げる
    th2 = (th2 + 180) % 360 - 180
    if 25 <= th2 <= 180 or th2 < -165:
        return 1
    if -20 <= th2 < 25:
        return 2
    if -125 <= th2 < -20:
        return 3
    return 2  # 北西

for y in range(H):
    for x in range(W):
        r, th = polar(x, y)
        if r > edge_r(th):
            continue
        if r < massif_r(th):
            hgt[y][x] = 5
        else:
            hgt[y][x] = ring_height(x, y, r, th)
            # 外側を1段低くして、段々にする（東と北東だけ）
            if hgt[y][x] >= 2 and r > edge_r(th) - 0.16 and -100 < th < 20:
                hgt[y][x] -= 1

def land(x, y):
    return inside(x, y) and hgt[y][x] is not None

def is_massif(x, y):
    r, th = polar(x, y)
    return land(x, y) and r < massif_r(th)

# --- 川：山の上の泉から南へ流れ、山の崖で滝になり、南の道を横切って島のふちから落ちる ---
SPRING = (56, 31)
def river_x(y):
    return 56 + 2.0 * math.sin((y - 30) / 6.0)
for y in range(H):
    for x in range(W):
        if not land(x, y):
            continue
        d_spring = math.hypot(x - SPRING[0], (y - SPRING[1]) * 1.2)
        if d_spring < 3.2:
            obj[y][x] = '~'
        elif y > SPRING[1] and abs(x - river_x(y)) < 1.4:
            obj[y][x] = '~'
            r, th = polar(x, y)
            # 山のすぐ外は、滝の途中の段（高さ3）
            if not is_massif(x, y) and r < massif_r(th) + 0.07:
                hgt[y][x] = 3
# 南の道の橋（川を東西に渡る）
BRIDGE_Y = 57
for x in range(W):
    if land(x, BRIDGE_Y) and obj[BRIDGE_Y][x] == '~':
        obj[BRIDGE_Y][x] = '='
# 川の両側の滝の段（高さ3）の岸も3にして、崖の段を見せる
for y in range(H):
    for x in range(W):
        if land(x, y) and obj[y][x] == '.' and not is_massif(x, y):
            r, th = polar(x, y)
            if r < massif_r(th) + 0.07 and abs(x - river_x(y)) < 2.6 and y > SPRING[1]:
                hgt[y][x] = 3

# --- 北東の池：島の東のふちへ滝になって落ちる ---
POND = (85, 17)
for y in range(H):
    for x in range(W):
        if not land(x, y):
            continue
        if math.hypot(x - POND[0], (y - POND[1]) * 1.3) < 3.4:
            obj[y][x] = '~'
        if 15 <= y <= 17 and x > POND[0] and obj[y][x] == '.':
            obj[y][x] = '~'  # 池から東のふちへ流れる

# --- 北の裂け目（奈落） ---
def carve_path(points, width, mark='.'):
    cells = set()
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        n = int(max(abs(x1 - x0), abs(y1 - y0)) * 3) + 1
        for i in range(n + 1):
            t = i / n
            px, py = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
            for dy in range(-3, 4):
                for dx in range(-3, 4):
                    if math.hypot(dx, dy) <= width:
                        cells.add((int(round(px)) + dx, int(round(py)) + dy))
    return cells

RIFTS = [[(58, 14), (60, 10), (59, 6), (61, 2)], [(45, 16), (44, 11), (46, 7), (45, 2)]]
for line in RIFTS:
    for c in carve_path(line, 1.6):
        x, y = c
        if land(x, y) and not is_massif(x, y):
            obj[y][x] = '_'
# 裂け目を渡る細い道（1マスの幅）
for (x0, x1, y) in [(55, 64, 8), (41, 50, 12)]:
    for x in range(x0, x1 + 1):
        if land(x, y) and obj[y][x] == '_':
            obj[y][x] = '.'

# --- 草木 ---
def density_at(x, y, r, th):
    if x < CX and y >= WALL_Y + 2:
        return 0.04  # 草地は少なめ
    if -165 <= th <= -125 or (th > 165 or th < -165):
        return 0.5  # 北西の森・西の小道
    if -20 <= th < 25:
        return 0.12
    if is_massif(x, y):
        return 0.05
    return 0.10

for y in range(H):
    for x in range(W):
        if not land(x, y) or obj[y][x] != '.':
            continue
        r, th = polar(x, y)
        p = density_at(x, y, r, th)
        # 島のふちの近くは木を多めに
        if r > edge_r(th) - 0.06:
            p += 0.25
        if rng.random() < p:
            k = rng.random()
            if -165 <= th <= -125:
                obj[y][x] = 'P' if k < 0.45 else ('T' if k < 0.85 else 'B')
            else:
                obj[y][x] = 'T' if k < 0.55 else ('B' if k < 0.85 else 'P')
        elif rng.random() < 0.05:
            obj[y][x] = 'F'

# 南東の岩の出っぱり
for (x0, y0, w, h) in [(66, 52, 3, 2), (72, 58, 2, 3), (62, 46, 2, 2)]:
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            if land(x, y) and not is_massif(x, y):
                obj[y][x] = 'R'

# --- 頂上への階段（北西の森から山の切れ込みを登る） ---
STAIR_Y = (33, 34)
x_edge = min(x for x in range(W) if is_massif(x, STAIR_Y[0]))
for y in STAIR_Y:
    for i, h in enumerate([2, 2, 3, 3, 4, 4]):
        hgt[y][x_edge + i] = h
        obj[y][x_edge + i] = '.'
STAIR_TOP = (x_edge + 6, STAIR_Y[0])

# --- 道を必ず通れるようにする（決めた道すじの木などをどける） ---
ROUTE = [(18, 52), (30, 56), (44, 57), (52, 57), (60, 57), (68, 55), (78, 50), (80, 44), (90, 41), (90, 37), (80, 37),
         (80, 33), (90, 33), (90, 29), (84, 24), (78, 18), (70, 12), (64, 8), (55, 8), (52, 10), (50, 12), (41, 12),
         (38, 14), (30, 16), (20, 18), (8, 22), (6, 25), (12, 27), (24, 27), (31, 28), (31, 30), (28, 33), (20, 36), (12, 40)]
W_ROUTE = [(28, 33), (STAIR_TOP[0], 33), (50, 28)]
for c in carve_path(ROUTE, 1.0) | carve_path(W_ROUTE, 1.0):
    x, y = c
    if land(x, y) and obj[y][x] in 'TBPRF' and (y not in (WALL_Y, WALL_Y + 1)):
        obj[y][x] = '.'

# 東の段々畑：茂みの生け垣を、山のふちから島のふちまで並べる。すきまは内側と外側で互い違い
def hedge_row(y, x_from, x_to, gap_inner, ch='B'):
    xs = [x for x in range(x_from, x_to) if land(x, y) and not is_massif(x, y)]
    if not xs:
        return
    gap = xs[:2] if gap_inner else xs[-3:-1]
    for x in xs:
        if x in gap:
            obj[y][x] = '.'
        elif obj[y][x] != '~':
            obj[y][x] = ch
for i, y in enumerate([28, 33, 38, 43]):
    hedge_row(y, 60, W, i % 2 == 0)

# 北西の森の木の列：西のふちから山のふちまで。すきまは 24行が西の端、29行が東の端（山のそば）
hedge_row(24, 0, CX, True, 'P')
hedge_row(29, 0, CX, False, 'T')

# --- 西の岩の壁と門 ---
GATE = (12, WALL_Y)
for y in (WALL_Y, WALL_Y + 1):
    for x in range(W):
        if land(x, y) and not is_massif(x, y) and x < CX:
            obj[y][x] = 'R'
obj[GATE[1]][GATE[0]] = 'D'
obj[GATE[1] + 1][GATE[0]] = '.'  # 門の草地側は1マス空ける

# --- 目印 ---
CHECKPOINT = (18, 52)
GOAL = (50, 28)
obj[CHECKPOINT[1]][CHECKPOINT[0]] = 'C'
obj[GOAL[1]][GOAL[0]] = 'G'
# たき火の周りは空ける
for dy in range(-3, 4):
    for dx in range(-4, 6):
        x, y = CHECKPOINT[0] + dx, CHECKPOINT[1] + dy
        if (dx, dy) != (0, 0) and land(x, y) and obj[y][x] in 'TBPRF':
            obj[y][x] = '.'
for dy in range(-2, 3):
    for dx in range(-2, 3):
        x, y = GOAL[0] + dx, GOAL[1] + dy
        if (dx, dy) != (0, 0) and obj[y][x] in 'TBPRF':
            obj[y][x] = '.'

# --- 落ちたら出られないくぼみをなくす（入れるのに、たき火の草地へ歩いて戻れないマスは茂みでふさぐ） ---
from collections import deque
def walkable(x, y):
    return land(x, y) and obj[y][x] not in 'RTPB~_D'
def can_step(a, b):
    d = hgt[b[1]][b[0]] - hgt[a[1]][a[0]]
    return -3 <= d <= 1
def reach(start, reverse=False):
    seen = {start}; q = deque([start])
    while q:
        c = q.popleft()
        for dx, dy in ((1,0),(-1,0),(0,1),(0,-1)):
            n = (c[0]+dx, c[1]+dy)
            if n in seen or not walkable(*n):
                continue
            if (can_step(n, c) if reverse else can_step(c, n)):
                seen.add(n); q.append(n)
    return seen
while True:
    fwd = reach(CHECKPOINT)
    back = reach(CHECKPOINT, True)
    trapped = [c for c in fwd if c not in back]
    if not trapped:
        break
    print('ふさぐくぼみ', sorted(trapped))
    for x, y in trapped:
        obj[y][x] = 'B'

with open('heights.txt', 'w') as f:
    f.write('\n'.join(''.join('.' if h is None else str(h) for h in row) for row in hgt))
with open('objects.txt', 'w') as f:
    f.write('\n'.join(''.join(row) for row in obj))
