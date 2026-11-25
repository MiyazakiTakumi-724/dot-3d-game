class_name GameSettings
extends RefCounted
## 設定（インベントリ画面の「設定」のページで変える）。難易度と、画面が白く光る演出の強さ。
## 簡単モードでは、敵から受けるダメージだけが半分になる（design.md 13章）。
## 光を弱める（2026-11-25 の設計 5章）：ブライトの光で画面が白くなるのを、弱く（0.4）できる。

var easy_mode := false
var soft_flash := false

## 画面を白くする光の強さ（0〜1）。
func flash_strength() -> float:
	return 0.4 if soft_flash else 1.0
