class_name Gravestone
extends RefCounted
## 死んだ場所に残る墓石。叩いて壊すと中身が手元に戻る。世界に1つだけ。

## 墓石があるエリア
var area_id: String = ""
var cell: Vector2i
var money: int = 0
## 墓石に入った素材・道具・矢（id → 数）
var counts := {}
## 墓石に入った武器と防具（Equipment.take_for_grave の結果。品物の id の配列）
var equipment: Array = []
