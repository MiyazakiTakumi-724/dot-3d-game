class_name WorldMap
extends RefCounted
## 大陸。エリアは大陸の上で重ならない長方形で、出口でつながる2つのエリアは辺を接して並ぶ。
## 出口は、相手のエリアの、大陸の上で同じ場所の出口とつながる。後で全体マップを描くときは、エリアの長方形を並べるだけでよい。

var _areas := {}

func add(a: AreaDef) -> void:
	_areas[a.id] = a

func area(id: String) -> AreaDef:
	return _areas.get(id)

func ids() -> Array:
	return _areas.keys()

## cell が出口のマスで、push（外へ歩こうとした向き）がその出口の外向きなら、その出口。なければ null。
func exit_through(area_id: String, cell: Vector2i, push: Vector2i) -> ExitDef:
	var a := area(area_id)
	if a == null or push == Vector2i.ZERO:
		return null
	for ex in a.exits:
		if ex.outward() == push and ex.has_cell(cell, a.size()):
			return ex
	return null

## 出口を出た先。{"area": 相手のエリア, "cell": 相手の出口の1マス内側}
func arrival(area_id: String, exit: ExitDef, cell: Vector2i) -> Dictionary:
	var a := area(area_id)
	var b := area(exit.target)
	var outside: Vector2i = a.origin + cell + exit.outward()
	var local: Vector2i = outside - b.origin
	return {"area": b.id, "cell": local + exit.outward()}

## 相手のエリアの、この出口とつながる出口。
func partner(area_id: String, exit: ExitDef) -> ExitDef:
	var b := area(exit.target)
	if b == null:
		return null
	for ex in b.exits:
		if ex.target == area_id and ex.outward() == -exit.outward():
			return ex
	return null

## データの問題を文字で返す。問題がなければ空。
func problems() -> Array[String]:
	var out: Array[String] = []
	var list := _areas.values()
	for i in list.size():
		for j in range(i + 1, list.size()):
			if list[i].rect().intersects(list[j].rect()):
				out.append("%s と %s が重なっている" % [list[i].id, list[j].id])
	for a in list:
		for ex in a.exits:
			if area(ex.target) == null:
				out.append("%s の出口の相手 %s がない" % [a.id, ex.target])
				continue
			var p := partner(a.id, ex)
			if p == null:
				out.append("%s→%s の出口に、向かい合う出口がない" % [a.id, ex.target])
				continue
			var b := area(ex.target)
			var mine := {}
			for c in ex.cells(a.size()):
				mine[a.origin + c + ex.outward()] = true
			var theirs := {}
			for c in p.cells(b.size()):
				theirs[b.origin + c] = true
			if mine.keys().size() != theirs.keys().size() or not mine.keys().all(func(k): return theirs.has(k)):
				out.append("%s→%s の出口が、相手の出口と大陸の上で重ならない" % [a.id, ex.target])
	return out
