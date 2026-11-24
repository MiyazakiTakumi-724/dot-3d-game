# 大陸のエリアの地図を作るスクリプト

`scripts/areas/` の camp.gd・rocks.gd・hills.gd・forest.gd は、ここの `gen.py` が作ったもの。
地図・出口・敵・拾いものを直すときは、`gen.py` を直して作り直す（.gd を手で直すと、次に作り直したときに消える）。

```sh
cd tools/area_maps
python3 gen.py              # 4エリアを作って scripts/areas/*.gd に書き出す。経路の長さも出す
python3 gen.py --preview    # preview_<エリア>.png も作る（Pillow が要る）
cd ../.. && ./run_tests.sh test_areas_layout.gd
```

- 大陸の上の置き方と出口のつながりは、`gen.py` の先頭の AREAS と EXITS。出口は相手の出口と大陸の上で重なること（テストが確かめる）。
- 乱数の種は固定なので、同じスクリプトからは毎回同じ地図になる。
- 地形の作り方：ノイズで細かい段差 → 崖のある高台・台地 → 木や川の列で道を折り返す → 出口の前を平らにする → 敵1の平地 → つながりを確かめ、戻れないくぼみを茂みでふさぐ。
- 経路の目安：たき火→丘陵→奥の森の強い鉄球まで90秒以上、門を開けた後の帰りは30秒以内。
- preview_*.png は git に入れない。
