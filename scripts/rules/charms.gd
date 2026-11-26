class_name Charms
extends RefCounted
## 装飾品（2026-11-26 独自の開発1）【提案】。テラリアやコアキーパーのように、探して見つける小さな力。
## 6つは幻の橋の向こうの宝箱にあり、狩人の矢筒は町の道具屋で買える。持っているだけで効き、死んでもなくならない（大事な物）。
## 品物は ItemCatalog.KEYS に入れる（名前と説明）。ここでは効き目の数を持つ。

const CAPE := "charm_cape"
const GLOVES := "charm_gloves"
const HAWK := "charm_hawk"
const RING := "charm_ring"
const QUIVER := "charm_quiver"
const EYE := "charm_eye"
const BOOTS := "charm_boots"

const ALL := [CAPE, GLOVES, HAWK, RING, QUIVER, EYE, BOOTS]

## 羽根のマント：飛び降りられる段数に足す
const CAPE_DROP := 2
## 岩の手袋：敵を押す距離と、転がる岩のダメージの倍率
const GLOVES_MULT := 1.5
## 鷹の目：弓の届く距離の倍率
const HAWK_RANGE := 1.25
## 月の指輪：マナの戻りの倍率
const RING_REGEN := 1.5
## 狩人の矢筒：矢を使わない割合
const QUIVER_SAVE := 0.25
## 瞳の首飾り：幻の橋が見える向きのはばの倍率
const EYE_VIEW := 1.6
## 登山靴：2段のよじ登りが、技能がなくてもでき、この秒で登る
const BOOTS_CLIMB := 0.3

static func has(inv: Inventory, id: String) -> bool:
	return inv != null and inv.count(id) > 0

## 持っている装飾品の数。
static func owned(inv: Inventory) -> int:
	var n := 0
	for id in ALL:
		if has(inv, id):
			n += 1
	return n

static func is_charm(id: String) -> bool:
	return id in ALL
