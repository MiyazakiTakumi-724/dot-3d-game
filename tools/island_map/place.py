# 敵と拾えるものを道の近くに置き、GDScript の定数にする
import math
exec(open('check.py').read().split("if __name__")[0])
dc = bfs(C)
# C から G への道（BFSの最短経路）
path = []
c = G
while c != C:
    path.append(c)
    for dx, dy in ((1,0),(-1,0),(0,1),(0,-1)):
        n = (c[0]+dx, c[1]+dy)
        if dc.get(n) == dc[c] - 1:
            df = h(c) - h(n)
            if -3 <= df <= 1:
                c = n; break
path.append(C)
path.reverse()
print('path', len(path))

def walker_cells(start, d, steps=4000, dt=0.05):
    """EnemyWalker と同じ動きで、通るマスを集める"""
    px, py = start[0]*16+8.0, start[1]*16+8.0
    dx, dy = d
    hh = h(start)
    seen = set()
    for i in range(steps):
        cell = (int(px // 16), int(py // 16))
        seen.add(cell)
        ax, ay = px + dx*8.1, py + dy*8.1
        ahead = (int(ax // 16), int(ay // 16))
        if ahead != cell:
            blocked = not ok(ahead, False) or h(ahead) != hh
            # 水と奈落は ok で弾かれる
            if blocked:
                dx, dy = -dx, -dy
                continue
        px += dx*24*dt; py += dy*24*dt
    return seen

def cheb(a, b):
    return max(abs(a[0]-b[0]), abs(a[1]-b[1]))

DIRS = {(1,0): 'Vector2.RIGHT', (-1,0): 'Vector2.LEFT', (0,1): 'Vector2.DOWN', (0,-1): 'Vector2.UP'}
enemies = []
used = set()
i = 34
while i < len(path) - 4:
    p = path[i]
    q = path[min(i+2, len(path)-1)]
    along = (q[0]-p[0], q[1]-p[1])
    perp = [(0,1),(0,-1)] if abs(along[0]) >= abs(along[1]) else [(1,0),(-1,0)]
    best = None
    for d in perp + [(1,0),(-1,0),(0,1),(0,-1)]:
        cells = walker_cells(p, d)
        if len(cells) >= 4 and all(cheb(c2, C) > 8 for c2 in cells) and p not in used:
            best = (d, cells); break
    if best and h(p) == h(path[i-1]) and OB[p[1]][p[0]] == '.':
        enemies.append((p, best[0], len(best[1])))
        used |= best[1]
        i += 16
    else:
        i += 1
print('enemies', len(enemies))
for e in enemies: print(e)

def side_cell(i, want=3):
    """道の i 番目の近くで、道から少し外れた拾える場所"""
    p = path[i]
    onpath = set(path)
    best = None; bd = -1
    for dy in range(-4, 5):
        for dx in range(-4, 5):
            c2 = (p[0]+dx, p[1]+dy)
            if c2 not in dc or OB[c2[1]][c2[0]] != '.' or c2 in onpath:
                continue
            d = min(abs(c2[0]-o[0]) + abs(c2[1]-o[1]) for o in path[max(0,i-12):i+12])
            if d <= want and d > bd and h(c2) == h(p):
                bd = d; best = c2
    return best

kinds = [(20, 'MONEY', 5), (60, 'MONEY', 10), (95, 'HEAL', 1), (120, 'MATERIAL', 1), (150, 'MONEY', 10),
         (175, 'HEAL', 1), (200, 'MONEY', 15), (215, 'MATERIAL', 1), (235, 'HEAL', 1), (255, 'MONEY', 15),
         (270, 'MATERIAL', 1), (290, 'HEAL', 1), (300, 'MONEY', 20)]
pickups = []
for i, k, a in kinds:
    c2 = side_cell(i)
    pickups.append((c2, k, a))
# 強い鉄球：北東の池のそばの行き止まり（道から遠い、届くマス）
best = None
for y in range(8, 24):
    for x in range(80, 96):
        c2 = (x, y)
        if c2 in dc and OB[y][x] == '.':
            d = min(abs(x-o[0]) + abs(y-o[1]) for o in path)
            if best is None or d > best[0]:
                best = (d, c2)
pickups.append((best[1], 'STRONG_BALL', 0))
print('pickups', pickups)
for p in pickups:
    assert p[0] is not None
with open('consts.gd', 'w') as f:
    f.write('const ENEMIES := [\n')
    for p, d, n in enemies:
        f.write('\t[Vector2i(%d, %d), %s],\n' % (p[0], p[1], DIRS[d]))
    f.write(']\n')
    f.write('const PICKUPS := [\n')
    for p, k, a in pickups:
        f.write('\t[Vector2i(%d, %d), RunState.PickupKind.%s, %d],\n' % (p[0], p[1], k, a))
    f.write(']\n')
