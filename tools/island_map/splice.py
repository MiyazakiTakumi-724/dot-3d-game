# gen.py・place.py の結果（heights.txt, objects.txt, consts.gd）を scripts/game/area_02.gd の定数に書き込む
import os
here = os.path.dirname(os.path.abspath(__file__))
os.chdir(here)
HG = open('heights.txt').read().split('\n')
OB = open('objects.txt').read().split('\n')
consts = open('consts.gd').read()
p = os.path.join(here, '..', '..', 'scripts', 'game', 'area_02.gd')
s = open(p, encoding='utf-8').read()
def arr(name, rows):
    return 'const %s := [\n' % name + ''.join('\t"%s",\n' % r for r in rows) + ']\n'
a = s.index('const HEIGHTS := ['); b = s.index('const PLAYER_START')
s = s[:a] + arr('HEIGHTS', HG) + arr('OBJECTS', OB) + s[b:]
a = s.index('const ENEMIES := ['); b = s.index('## 門を開けるときに立つ奥側のマス')
s = s[:a] + consts + s[b:]
open(p, 'w', encoding='utf-8').write(s)
print('wrote', p)
