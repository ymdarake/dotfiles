# プロジェクト設定 (Terraform)

Terraformプロジェクト用の設定として `.claude/CLAUDE.md` に配置するファイルです。

## このプロジェクトについて

<!-- ⚠️ 【要記入】このセクションをプロジェクトに合わせて編集してください -->

**技術スタック:**
- [ ] IaC: Terraform
- [ ] クラウドプロバイダー: (例: AWS, GCP, Azure など)
- [ ] その他: (例: バックエンドストレージ、CI/CDツール など)

**プロジェクトの目的:**
<!-- プロジェクトの概要を簡潔に記述 -->

## Bashコマンド

<!-- ⚠️ 【要記入】プロジェクトで実際に使うコマンドに修正してください -->

```bash
terraform init             # 初期化（プロバイダーダウンロード）
terraform plan             # 実行計画を確認
terraform apply            # インフラをプロビジョニング
terraform apply -auto-approve  # 確認なしで適用
terraform destroy          # リソースを削除
terraform fmt              # コードフォーマット
terraform validate         # 構文チェック
terraform state list       # 管理中のリソース一覧
terraform state show <resource>  # リソース詳細表示
terraform output           # Output変数を表示
terraform workspace list   # ワークスペース一覧
terraform workspace select <name>  # ワークスペース切り替え
```

## プロジェクト構成

<!-- ⚠️ 【要記入】プロジェクトの実際のディレクトリ構造を記入してください -->

```
.
├── main.tf           # メインの設定
├── variables.tf      # 変数定義
├── outputs.tf        # Output定義
├── versions.tf       # Terraformバージョン・プロバイダー定義
├── terraform.tfvars  # 変数の値（環境ごと）
├── backend.tf        # バックエンド設定（S3等）
├── modules/          # 再利用可能なモジュール
│   ├── vpc/
│   ├── ec2/
│   └── rds/
└── environments/     # 環境ごとの設定
    ├── dev/
    ├── staging/
    └── prod/
```

## コーディングスタイル

- リソース名: snake_case
- 変数名: snake_case
- モジュール名: kebab-case
- インデント: スペース2つ
- `terraform fmt` でフォーマット必須
- 1ファイルは300行以内を目安

## ベストプラクティス

### 変数定義

```hcl
variable "environment" {
  description = "環境名（dev, staging, prod）"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "環境名はdev, staging, prodのいずれかである必要があります"
  }
}
```

### リソースの命名規則

```hcl
resource "aws_instance" "web_server" {
  # ${環境}_${用途}_${リソース種別}
  tags = {
    Name = "${var.environment}-web-server"
  }
}
```

### モジュール化

- 再利用可能な構成はモジュール化
- モジュールには README.md を用意
- Input/Output を明確に定義

## セキュリティ

- **秘密情報をコードに直接書かない**
- 認証情報は環境変数または AWS/GCP の認証機構を使用
- `.tfvars` ファイルは `.gitignore` に追加
- `terraform.tfstate` は Git にコミットしない（リモートバックエンド使用）
- センシティブな変数には `sensitive = true` を設定

```hcl
variable "db_password" {
  type      = string
  sensitive = true
}
```

## State管理

- リモートバックエンド（S3 + DynamoDB）を使用
- State ロックを有効化
- 環境ごとにワークスペースまたは別バックエンドを使用

## テスト・検証

- `terraform plan` で変更内容を必ず確認
- `terraform validate` で構文チェック
- Terratest や kitchen-terraform でテスト（推奨）
- Checkov / tfsec でセキュリティスキャン

## Git運用

- `terraform apply` 前に必ず `plan` を確認
- 本番環境への適用は慎重に
- PR には `terraform plan` の出力を添付
- インフラ変更は小さく頻繁に

---

*参考: [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)*
