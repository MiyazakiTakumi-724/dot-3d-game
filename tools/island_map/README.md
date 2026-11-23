# 試作2の島の地図を作るスクリプト

`scripts/game/area_02.gd` の HEIGHTS・OBJECTS・ENEMIES・PICKUPS は、ここのスクリプトで作った。
小さな直しなら area_02.gd を直接書き換えてよい。島の形や道すじを大きく変えるときはここを直して作り直す。

```sh
cd tools/island_map
python3 gen.py      # 島の形・段・川・池・裂け目・草木・生け垣・階段 → heights.txt, objects.txt
python3 check.py preview.png   # 経路の長さ（たき火→ゴール、たき火→門の奥、門を開けたとき）とプレビュー画像（Pillow が要る）
python3 place.py    # 道の近くに敵と拾えるものを置く → consts.gd
python3 splice.py   # area_02.gd の定数を書き換える
cd ../.. && ./run_tests.sh test_area_02_layout.gd
```

- 乱数の種は固定なので、同じスクリプトからは毎回同じ地図になる。
- 門の位置（DOOR_OPEN_FROM）と PLAYER_START は area_02.gd に直接書いてある。gen.py の GATE・CHECKPOINT を変えたら合わせて直す。
- 生成物（*.txt, consts.gd, preview.png）は git に入れない。
