package schema

// #Environment: 環境の型定義
// - id: 環境URN（"urn:env:" + envId）
// - envId: 環境識別子（dev/stg/prod等）
#Environment: {
	// envId（環境識別子）
	envId: string
	envId: "dev" | "stg" | "prod" | string

	// id は envId から自動導出
	id: "urn:env:\(envId)"

	// YAGNI: 接続情報などの詳細は将来必要になったら追加
}
