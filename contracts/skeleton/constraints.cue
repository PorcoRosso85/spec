package skeleton

import "list"

// 一意制約: slotId 重複禁止
#UniqueSlotIds: {
	slots: [...#Slot]

	_slotIds: [for slot in slots {slot.slotId}]
	_unique: list.UniqueItems(_slotIds) == true
}

// schema_version厳密チェック
#StrictVersion: {
	schema_version: "1" // 文字列"1"のみ許可
}

// narHash存在チェック
#RequireNarHash: {
	narHash: string & !="" // rootレベル必須

	slots: [...{
		manifest: {
			narHash: string & !="" // per-node必須
		}
	}]
}

// status厳密チェック（treeFinalではactiveのみ）
#ActiveOnly: {
	slots: [...{
		status: "active" // provisionalは許可しない
	}]
}
