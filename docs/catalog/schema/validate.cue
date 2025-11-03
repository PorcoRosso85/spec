// docs/catalog/schema/validate.cue
// CIが守るべきルール(仕様書)。実装は別PR。
//
// - responsibility は1文
// - status=="active" なら owner 必須
// - "abstract" な slot.id は skeleton.json に出してはならない
// - dependsOn は slot-catalog.cue 内のidだけ
// - 明らかな循環や自己参照は禁止
// - responsibility の重複(ほぼ同じ文)を警告してDRYを保つ

package catalog
