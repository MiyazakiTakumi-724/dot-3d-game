# CLAUDE.md

sprite stacking（輪切りのドット絵を重ねて3Dに見せる手法）を使った、見下ろしアクションゲーム。Godot 4 / GDScript で作り、Steamでのリリースを目指す。開発者は1人で、ゲーム制作は初めて。ユーザーとのやり取りは日本語で行う。

## まず読むもの

1. `docs/design.md`：ゲーム全体の仕様。ここを正とする。【提案】が付いた項目はClaudeの提案で、ユーザーの明確な承認はまだない。
2. `docs/next-prototype-death-loop.md`：次に作るもの。中身の設計はまだなので、ユーザーと詰めてから実装する。
3. `docs/superpowers/plans/2026-11-23-iron-ball-prototype.md`：試作1の実装計画（完了済み）。

## 現状

試作1「鉄球の1ステージ」は完成している。高さ0〜3の台地と壁があるエリアに敵が3体いて、高い所から鉄球を落として全滅させるとクリアになる。テストはGUTで58件、すべて通る。

## コマンド

```sh
./run_tests.sh                    # 全テスト（GUT、headless）
./run_tests.sh test_iron_ball.gd  # 1ファイルだけ
```

- `run_tests.sh` は、`godot` コマンドにPATHが通っている前提。Windowsでは Godot の実行ファイルに置き換えるか、エディタのGUTパネルから実行する。
- ゲームの実行は、Godotエディタで `project.godot` を開いてF5を押す。

## 構成

```
scripts/rules/   ゲームのルール。RefCounted で描画に依存しないので、単体テストできる
  movement_rules.gd  登れる段数（1）・飛び降りられる段数（3）。Resourceなので後でアイテムで変えられる
  height_map.gd      マスごとの高さと壁。マップの外は壁として扱う
  player_mover.gd    高さを考えた移動。段差は自動で登る。front_cell() は「目の前のマス」
  iron_ball.gd       鉄球の状態（HELD/FALLING/ON_GROUND）、ダメージ、拾い直し
  bullet.gd          敵の弾。通り道のマスを1つずつ調べて、壁の角でもすり抜けない
  enemy_walker.gd    敵の往復移動と体力
  stage_state.gd     クリア・ゲームオーバーの判定
scripts/render/  描画まわり
  voxel_model.gd     ボクセルの形から輪切り画像を作る（今の素材はすべてコードで生成）
  stack_camera.gd    カメラの回転、ワールド座標から画面座標への変換、マウス操作
  stack_sprite.gd    輪切りを重ねて描くノード。動くものは sort_by_cell=true にする
scripts/game/    ノード（ルールのクラスを持って描画するだけの薄い層）とステージ
scenes/stage_01.tscn  メインシーン
tests/           GUTのテスト（test_*.gd）
addons/gut/      GUT 9.5.0（同梱。Godot 4.5向け）
```

## 決まりごと

- 新しいゲームのルールは `scripts/rules/` に RefCounted クラスとして書き、先にGUTで失敗するテストを書いてから実装する（TDD）。
- 座標系：1マス＝16px、1段＝輪切り8枚＝画面で8px。描画解像度は320×180で、拡大は整数倍のみ。
- カメラ：`world_to_screen` は -angle で回し、`screen_dir_to_world` は +angle で回す。符号をそろえること。
- 描画順：`z_index` は奥行き（カメラ基準で回したときのy）で決める。動くものは自分が立っているマスの中心で判定する（そうしないと、マスの奥側に立ったとき足元が床に隠れる）。
- コメントとコミットメッセージは日本語。
- UIの文字は今は英語（標準フォントに日本語がないため）。

## 既知の小さな問題（未対応）

- 台地に置いた鉄球が、階段を降りている途中で足元へ戻ってくることがある。届くかどうかを今の高さだけで判定しているため。
- 壁や崖に、キャラが2〜3pxめり込む。当たり判定がキャラの中心の1点だけのため。
- 台地の上のプレイヤーに弾が当たるとき、見た目では24px下に当たって見える。弾が撃った敵の高さで描かれるため。

## 進め方

ユーザーは superpowers のスキルで進めてきた。brainstorming → 設計の承認 → writing-plans → executing-plans（まとめてチェック方式）。実装に入る前に、必ず設計をユーザーに承認してもらうこと。
