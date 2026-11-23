class_name Gravestone
extends RefCounted
## 死んだ場所に残る墓石。叩いて壊すと中身が手元に戻る。世界に1つだけ。

var cell: Vector2i
var money: int = 0
var materials: int = 0
var heals: int = 0
var has_strong_ball := false
