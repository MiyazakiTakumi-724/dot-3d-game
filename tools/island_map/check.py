# 地図の確かめ：経路の長さと、プレビュー画像
import sys
from collections import deque
from PIL import Image
HG = open('heights.txt').read().split('\n')
OB = open('objects.txt').read().split('\n')
H = len(HG); W = len(HG[0])
def find(ch):
    return [(x, y) for y in range(H) for x in range(W) if OB[y][x] == ch]
C = find('C')[0]; G = find('G')[0]; D = find('D')
def h(c):
    return int(HG[c[1]][c[0]])
def ok(c, door):
    x, y = c
    if not (0 <= x < W and 0 <= y < H): return False
    if HG[y][x] == '.': return False
    o = OB[y][x]
    if o in 'RTPB~_': return False
    if o == 'D' and not door: return False
    return True
def bfs(a, door=False):
    q = deque([a]); d = {a: 0}
    while q:
        c = q.popleft()
        for dx, dy in ((1,0),(-1,0),(0,1),(0,-1)):
            n = (c[0]+dx, c[1]+dy)
            if n in d or not ok(n, door): continue
            df = h(n) - h(c)
            if df > 1 or df < -3: continue
            d[n] = d[c] + 1; q.append(n)
    return d
if __name__ == '__main__':
    dc = bfs(C)
    far = (D[0][0], D[0][1] - 1)
    print('C', C, 'G', G, 'gate', D, 'far', far)
    print('C->G', dc.get(G), ' C->far', dc.get(far), ' far->C(open)', bfs(far, True).get(C))
    print('reachable cells', len(dc), 'land', sum(1 for y in range(H) for x in range(W) if HG[y][x] != '.'))
    # プレビュー
    S = 6
    im = Image.new('RGB', (W*S, H*S), (12, 13, 22))
    px = im.load()
    for y in range(H):
        for x in range(W):
            if HG[y][x] == '.': continue
            hh = int(HG[y][x]); o = OB[y][x]
            g = 70 + hh * 30
            col = (40, min(255, g + 60), 40)
            if o in 'TP': col = (20, 90 + hh*10, 30)
            if o == 'B': col = (60, 140, 50)
            if o == 'R': col = (130, 130, 135)
            if o == '~': col = (60, 150 + hh*15, 220)
            if o == '=': col = (160, 110, 60)
            if o == '_': col = (0, 0, 0)
            if o == 'F': col = (230, 200, 230)
            if o in 'CGD': col = (255, 60, 60)
            if (x, y) not in dc and o not in 'RTPB~_=' : col = tuple(int(v*0.55) for v in col)
            for j in range(S):
                for i in range(S):
                    px[x*S+i, y*S+j] = col
    # 経路
    path = []
    if G in dc:
        c = G
        while c != C:
            path.append(c)
            for dx, dy in ((1,0),(-1,0),(0,1),(0,-1)):
                n = (c[0]+dx, c[1]+dy)
                if dc.get(n) == dc[c] - 1 and n in dc:
                    df = h(c) - h(n)
                    if -3 <= df <= 1:
                        c = n; break
    for (x, y) in path:
        for j in range(2, 4):
            for i in range(2, 4):
                px[x*S+i, y*S+j] = (255, 255, 0)
    im.save(sys.argv[1] if len(sys.argv) > 1 else 'preview.png')
