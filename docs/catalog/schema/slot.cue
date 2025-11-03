// docs/catalog/schema/slot.cue
// #Slot: スロットの型
// domain フィールドは持たない（domainなし）。tierは残す。

package catalog

#Slot: {
    id:             string
    responsibility: string // 1文, SRP
    owner?:         string // status=="active"なら必須
    dependsOn?:     [...string]
    status:         "abstract" | "active" | "deprecated"
    tier:           "business" | "app" | "infra"
    standardRef?:   [...string]
    notes?:         string
}
