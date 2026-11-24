class_name GameSettings
extends RefCounted
## 設定（インベントリ画面の「設定」のページで変える）。今は難易度だけ。
## 簡単モードでは、敵から受けるダメージだけが半分になる（design.md 13章）。

var easy_mode := false
