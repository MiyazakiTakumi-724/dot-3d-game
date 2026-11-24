# CLAUDE.md

sprite stacking（輪切りのドット絵を重ねて3Dに見せる手法）を使った、見下ろしアクションゲーム。Godot 4.7 / GDScript で作り、Steamでのリリースを目指す。開発者は1人で、ゲーム制作は初めて。ユーザーとのやり取りは日本語で行う。

## まず読むもの

1. `docs/design.md`：ゲーム全体の仕様。ここを正とする。【提案】が付いた項目はClaudeの提案で、ユーザーの明確な承認はまだない。
2. `docs/superpowers/specs/2026-11-24-world-areas-design.md`：試作3「大陸のエリアをつなぐ」の設計（ユーザー承認済み、実装済み）。試作2の設計と食い違う所はこちらが優先。計画は `docs/superpowers/plans/2026-11-24-world-areas.md`。
3. `docs/superpowers/specs/2026-11-23-death-loop-design.md`：試作2「死と取り返しの流れ」の設計（ユーザー承認済み）。持ち物・墓石・奈落のルールは試作3でもこのまま。
4. 古い計画（完了済み）：`docs/superpowers/plans/` の 2026-11-23・2026-11-24 の試作1・試作2のもの。

## 現状

試作1「鉄球の1ステージ」（`scenes/stage_01.tscn`）は完成している。高さ0〜3の台地と壁があるエリアに敵が3体いて、高い所から鉄球を落として全滅させるとクリアになる。

試作2「死と取り返しの流れ」で、死ぬとたき火から再開し、墓石に鉄球を落として持ち物を取り返す流れを作った。箱庭の島（area_02）は試作3で消した。

試作3「大陸のエリアをつなぐ」（`scenes/field.tscn`、今のメインシーン）を実装した。1つの大陸が4つのエリア（野営地・岩場・丘陵・奥の森）に分かれていて、今いるエリアだけを描く。地面の矢印の先へ歩くと、画面を暗くしてとなりのエリアに切り替わる（シーンは読み込み直さず、`field.gd` の `enter_area` が作り直す。となりのエリアの輪切り画像は、遊んでいる間に1フレーム10msまで少しずつ作っておく）。クリアはなく、遠いエリアほど敵と拾いものが強い。鉄球は手の届く範囲（1.5マス）の、自分より高くない地面の好きな場所に落とす。敵1は段差を登らず、敵2は1段登って近接攻撃する。倒した敵は5分後、別のエリアへ行ってから戻る（死んでも戻らない）。奥の森の門を開けると、野営地への近道になる。ユーザーが遊んで、世界のイメージに合うかを確かめる段階。

地図は手で書かずに、`tools/area_maps/gen.py` で作る（大陸の上の置き方と出口・高さ・崖・木の列・敵・拾いもの。使い方はそこの README）。`scripts/areas/*.gd` は生成物なので、直すときは gen.py を直して作り直す。出口の両側は高さを高い方にそろえ、生け垣の列は経路づくりで削らない。`tests/test_areas_layout.gd` が、出口のつながり・経路の長さ（強い鉄球まで90秒以上、門からの帰り30秒以内）・くぼみ・平地の広さなどを確かめる。

テストはGUTで225件、すべて通る（15秒くらい）。

### 操作（試作3）

WASD・矢印：移動／左クリック：手に持つアイテムを使う（鉄球はカーソルの場所に落とす。届くのは1.5マス）／1・2：手に持つアイテム（鉄球・回復）／Tab：インベントリ（装備するランクを決める、ポイントを振る。開いている間も世界は動く）／F：門を開ける／右ドラッグ・Q/E：カメラ／鉄球は近く（12px）を歩いて拾う。落ちているものはマスの中心から14pxで拾う。試作1は X/Z のまま。

## コマンド

```sh
./run_tests.sh                    # 全テスト（GUT、headless）
./run_tests.sh test_iron_ball.gd  # 1ファイルだけ
```

- `run_tests.sh` は、`godot` コマンドにPATHが通っている前提。Windowsでは Godot の実行ファイルに置き換えるか、エディタのGUTパネルから実行する。
- ゲームの実行は、Godotエディタで `project.godot` を開いてF5を押す。
- 画面の確認：`godot --path . res://scenes/field.tscn -- --screenshot=out.png --area=hills --player=x,y --angle=0.5`（`--inventory`・`--inventory=stats` で持ち物の画面、`--exp=30` で経験値を足す。`--fps` で平均FPSも出す。`--offset=dx,dy` でプレイヤーをマスの中心からずらし、`--ball=dx,dy` で鉄球をそばの地面に置く）。

## 構成

```
scripts/rules/   ゲームのルール。RefCounted で描画に依存しないので、単体テストできる
  movement_rules.gd  登れる段数（1）・飛び降りられる段数（3）。Resourceなので後でアイテムで変えられる
  height_map.gd      マスごとの高さと壁、奈落、水、島の外、ふさぐもの（墓石・閉じた扉）。マップの外と島の外は壁として扱う
  hotbar.gd          手に持つアイテム（数字キーで選ぶ）
  area_def.gd        1つのエリアのデータ（大陸の上の位置・地図・出口・敵・拾いもの）。entry_safe_cells は出口から3マス
  exit_def.gd        エリアの出口（辺・範囲・相手・門）
  world_map.gd       大陸。exit_through（出口を外へ歩いたか）、arrival（相手のエリアの着く所）、problems（データの確かめ）
  enemy_kind.gd      敵の種類（敵1 WEAK・敵2 MELEE・撃つ敵 SHOOTER）ごとの体力・攻撃力・経験値（レベルで伸びる）・登れる段・撃つか・体当たり
  melee_attack.gd    敵2の近接攻撃（0.5秒ためて叩く）
  enemy_roster.gd    倒した敵の復活の時間（300秒。エリアに入ったときだけ調べる）
  player_mover.gd    高さを考えた移動。段差は自動で登る。edge_push はマップの外へ歩こうとした向き（出口の判定）
  iron_ball.gd       鉄球の状態（HELD/FALLING/ON_GROUND）、ダメージ、拾い直し。drop_at で好きな点に落とす（24pxまで）、当たりは半径8px
  bullet.gd          敵の弾。撃った高さを飛び、壁と弾より高い地面で止まる。当たるのは同じ高さだけ（hits）。通り道のマスを1つずつ調べて、壁の角でもすり抜けない
  enemy_walker.gd    敵の往復移動と体力と体当たり（touches）。climb で登れる段数、chase で近くのプレイヤーへ寄る、forbidden に入らない
  stage_state.gd     試作1のクリア・ゲームオーバーの判定
  inventory.gd       持ち物（お金・素材・回復）と equipment
  equipment.gd       武器（鉄球・剣・弓・エアガン）と防具（頭・体・足）のランク。持っているランクと装備するランク。
                     死ぬとランク1以外は墓石へ（take_for_grave / restore）。ランク1つで攻撃力＋2（rank_attack）。強い鉄球＝鉄球のランク2
  player_stats.gd    レベル・経験値・振り分けポイント（体力・攻撃力・剣・弓・エアガン・体の動き）。3ポイントごとに技能
  damage.gd          ダメージの式（design.md 17章）。鉄球・敵の攻撃（簡単モードで半分）・敵のレベルでの伸び
  gravestone.gd      墓石の場所と中身
  run_state.gd       死んだときの持ち物の移し替え、拾い済み（"エリア:番号"）、開けた門、チェックポイント。墓石はエリアを覚える。
                     stats（PlayerStats、死んでも残る）と bosses_defeated（敵のレベル＝敵ごとのレベル＋この数）
  area_state.gd      PLAYING / DYING と再開のタイミング（CLEAR は試作2の名残で使っていない）
scripts/render/  描画まわり
  voxel_model.gd     ボクセルの形から輪切り画像を作る（今の素材はすべてコードで生成）。テクスチャは textures() で共有する
  stack_camera.gd    カメラの回転、ワールド座標から画面座標への変換、マウス操作。follow() で立っている高さを画面の真ん中にする。pick_ground はカーソルの下の地面の点
  stack_sprite.gd    輪切りを重ねて描くノード。shadow_radius で足元に影。動くものは sort_by_cell=true にする。画面外のものは描かない（visible を毎フレーム書き換えるので、隠すときは force_hidden を使う）。描き直すのはカメラの角度が変わったときだけ。地面の段のふちの明るい線は rim_sides で上から描く。向きが変わるもの（プレイヤー・敵）は always_redraw=true
scripts/game/    ノード（ルールのクラスを持って描画するだけの薄い層）とステージ
  terrain.gd         文字の地図の読み込みと地形の描画（ステージ共通）。1層の地図（試作1）と2層の地図（高さの層と物の層、箱庭）。
                     記号はファイルの先頭に書いてある。各マスは「隣が低くて見える所までの柱」として描く（column_bottom）。
                     島のふちの柱は0より下へ伸びて断面になり、水の柱の側面は滝になる。奈落と島の外は描かない。
                     高さを読みやすくする：段のふちの明るい線（lower_sides）、側面の段ごとの帯、top_color（高いほど明るい）。arrow_model は出口の矢印
  ui_text.gd         画面の文字（日本語のドット絵フォント PixelMplus 10px・12px）
  inventory_menu.gd  Tab で開くインベントリ画面（開いても世界は止まらない）。装備のページ（回る主人公の姿と枠、ランクを選ぶ）と
                     ステータスのページ（ポイントを振る、次の技能まであと何ポイント）
  damage_popup.gd    当たったときに出るダメージの数字
fonts/           PixelMplus（M+ FONT LICENSE。商用利用・再配布が自由）とライセンスの文。*.import はぼかさない設定なので git に入れている
scripts/areas/   4エリアのデータ（tools/area_maps/gen.py の生成物）と continent.gd（大陸をまとめる、START_AREA・START_CELL）
scripts/game/field.gd エリアを入れ替えるメインシーンの中身（enter_area・切り替え・死と再開・門・UI）
scenes/field.tscn     メインシーン（試作3）
scenes/stage_01.tscn  試作1
tests/           GUTのテスト（test_*.gd）。tests/helpers/ はテスト用の道具（経路探索など）
addons/gut/      GUT 9.5.0（同梱。Godot 4.5向けだが、gut_loader.gd の1行を直して 4.7 で動かしている）
```

## 決まりごと

- 新しいゲームのルールは `scripts/rules/` に RefCounted クラスとして書き、先にGUTで失敗するテストを書いてから実装する（TDD）。
- 座標系：1マス＝16px、1段＝輪切り8枚＝画面で8px。描画解像度は320×180で、拡大は整数倍のみ。
- カメラ：`world_to_screen` は -angle で回し、`screen_dir_to_world` は +angle で回す。符号をそろえること。
- 描画順：`z_index` は奥行き（カメラ基準で回したときのy）×8＋draw_bias で決める。動くものは足元の円がかかるマスのうち、同じ高さのマスの一番手前の中心で判定する（`StackSprite.sort_depth`。そうしないと、マスの奥側に立ったとき足元が床に隠れたり、手前のふちに立ったとき手前の床がかぶったりする。低いマスを数えると、崖の上の鉄球が下に立つキャラにかぶる）。木や岩は同じ奥行きならキャラより後（`Terrain.DECO_BIAS`）。
- コメントとコミットメッセージは日本語。
- UIの文字は日本語（`UiText` を使う。大きさは10pxか12pxのまま）。キーの名前は英字のまま。JIS第1・第2水準にない記号を使うときは、PixelMplus にあるか確かめる。

## 既知の小さな問題（未対応）

- 台地に置いた鉄球が、階段を降りている途中で足元へ戻ってくることがある。届くかどうかを今の高さだけで判定しているため。
- 全体マップの画面はまだない（エリアの位置のデータだけある）。
- 壁や崖に、キャラが2〜3pxめり込む。当たり判定がキャラの中心の1点だけのため。

## 進め方

ユーザーは superpowers のスキルで進めてきた。brainstorming → 設計の承認 → writing-plans → executing-plans（まとめてチェック方式）。実装に入る前に、必ず設計をユーザーに承認してもらうこと。
