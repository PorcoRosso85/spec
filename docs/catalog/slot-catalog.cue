// docs/catalog/slot-catalog.cue
// 全スロットの集約。このファイルが slot.id -> #Slot の唯一の正(SSOT)。
// CIはここを起点に整合性を確認する。

package catalog

// #Slot 型は schema/slot.cue を参照。
// 各エントリは "status": "abstract" | "active" | "deprecated".

slots: {
    // 例:
    // "nist80053.AC-access-control": #Slot & {
    //     id:            "nist80053.AC-access-control"
    //     responsibility: "アクセス制御/認可を行い不正アクセスを防ぐ"
    //     owner:         "" // status=="active" なら必須
    //     dependsOn:     []
    //     status:        "abstract"
    //     tier:          "app"
    //     standardRef:   ["nist80053-AC"]
    //     notes:         "初期ドラフト。まだskeleton.jsonに出してはならない"
    // }
}
