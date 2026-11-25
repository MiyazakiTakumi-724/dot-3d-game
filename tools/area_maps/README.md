# 大陸のエリアの地図を作るスクリプト

`scripts/areas/` のエリアのデータ（continent.gd 以外の30ファイル）は、ここの `gen.py` が作ったもの。
地図・出口・敵・拾いものを直すときは、`gen.py` を直して作り直す（.gd を手で直すと、次に作り直したときに消える）。

```sh
cd tools/area_maps
python3 gen.py              # 30エリアを作って scripts/areas/*.gd に書き出す
python3 gen.py --preview    # preview_<エリア>.png も作る（Pillow が要る）
cd ../.. && ./run_tests.sh test_areas_layout.gd
```

- 大陸の上の置き方と出口のつながりは、`gen.py` の先頭の AREAS と LINKS（つながる2つのエリアと、大陸の上のマスの範囲）。EXITS は LINKS から作る。
- エリアの作り方は MAKERS の関数（make_mt_1 など）。地方ごとの飾りは THEME_DECO。仕掛けは pocket（囲った宝）と barrier（帯を川で切り離す）、
  たき火の広場は plaza、ボスの居場所は boss、商人は merchant（お店の id）。ふつうのエリアは area()、休憩所は rest()。
  敵は spawn（地方ごとの種類 REGION_ENEMIES、段差を登らない敵には平地を作る）、拾いものは loot（地方ごとの LOOT、品物の id）。仕掛けの先は locked に入れ、つながりの確かめから外す（check_unlocked が、開けたら行けるかを確かめる）。
- 出口の両側の高さはそろえ、まわりへなだらかにつなぐ（ease_seam）。高さ -1 は島の外（塔の空）。
- 乱数の種は固定なので、同じスクリプトからは毎回同じ地図になる。
- 地形の作り方：ノイズで細かい段差 → 崖のある高台・台地 → 木や川の列で道を折り返す → 出口の前を平らにする → 敵1の平地 → つながりを確かめ、戻れないくぼみを茂みでふさぐ。
- 経路の目安：門を開けた後の帰りは30秒以内。エリアはせまく（ふつう16×16〜24×20、長いものでも32×14）。
- preview_*.png は git に入れない。
