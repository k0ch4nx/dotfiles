# 認証情報

## Terraform

- Terraform作成credentialの表示名は`tf-`で始める。手動管理credentialはprefixなし。

| 名称 | 発行元 | 権限・用途 | 利用場所 | 管理場所 |
|---|---|---|---|---|
| `CLOUDFLARE_API_TOKEN` | Cloudflare | Cloudflare、Terraform providerの認証 | GitHub Actions | GitHub Actions Secrets（手動管理） |
| `NIX_CACHE_CI_PRIVATE_KEY` | cache署名鍵の管理者 | CIのNix cache署名 | GitHub Actions | GitHub Actions Secrets |
| `cloudflare_account_id` | Terraform | Cloudflare account識別。secretではない | Terraform provider | `infra/dotfiles/variables.tf`のdefault |
| `bucket_name` | Terraform | R2 cache bucket設定。secretではない | Terraform、Cloudflare R2 | `infra/dotfiles/variables.tf`のdefault |
| `r2_ro_access_key_id` | TerraformがCloudflareで作成 | RO credentialのID。Nix cache substitutionの読み取り専用 | Nix daemon | Terraform state、HCP Terraform outputからruntime取得。GitHub Actions Secretでもagenixでもない |
| `r2_ro_secret_access_key` | TerraformがCloudflareで作成 | RO credentialのsecret。Nix cache substitutionの読み取り専用 | Nix daemon | Terraform state、HCP Terraform outputからruntime取得。GitHub Actions Secretでもagenixでもない |
| `r2_rw_access_key_id` | TerraformがCloudflareで作成 | RW credentialのID。cache push/touchの読み取り・書き込み | cache push/touch | Terraform state、HCP Terraform outputからruntime取得。GitHub Actions Secretでもagenixでもない |
| `r2_rw_secret_access_key` | TerraformがCloudflareで作成 | RW credentialのsecret。cache push/touchの読み取り・書き込み | cache push/touch | Terraform state、HCP Terraform outputからruntime取得。GitHub Actions Secretでもagenixでもない |

## 手動

| 名称 | 発行元 | 権限・用途 | 利用場所 | 管理場所 |
|---|---|---|---|---|
| `AUTOMATION_TOKEN` | GitHub | Terraform GitHub provider、更新PR、auto-mergeの認証 | GitHub Actions、Terraform | GitHub Actions Secrets |
| `TF_API_TOKEN` | HCP Terraform | CI専用。HCP Terraform stateの認証。ローカルtokenとは別 | GitHub Actions | GitHub Actions Secrets |
| `TF_TOKEN_app_terraform_io` | HCP Terraform | ローカルTerraform CLIの認証。CIの`TF_API_TOKEN`とは別 | ローカルTerraform、bootstrap | bootstrapがYubiKeyで`secrets/hcp-terraform-token.age`を復号し、実行時だけTerraformへ渡す |
| `nix-cache-local-private-key.age` | ユーザー | local Nix cache署名 | local Nix cache | `secrets/nix-cache-local-private-key.age` |

## SSH

| 名称 | 発行元 | 権限・用途 | 利用場所 | 管理場所 |
|---|---|---|---|---|
| `id_ed25519.age` | ユーザー | SSH接続 | `~/.ssh/id_ed25519` | `secrets/ssh/id_ed25519.age` |
| `id_ed25519_gh_work.age` | ユーザー | GitHub work SSH接続 | `~/.ssh/id_ed25519_gh_work` | `secrets/ssh/id_ed25519_gh_work.age` |
| `id_ed25519_sk.age` | ユーザー | security key SSH接続 | `~/.ssh/id_ed25519_sk` | `secrets/ssh/id_ed25519_sk.age` |
| `id_ed25519_sk_gh_auth_pers.age` | ユーザー | GitHub personal認証 | `~/.ssh/id_ed25519_sk_gh_auth_pers` | `secrets/ssh/id_ed25519_sk_gh_auth_pers.age` |
| `id_ed25519_gh_sign_pers.age` | ユーザー | GitHub personal署名 | `~/.ssh/id_ed25519_gh_sign_pers` | `secrets/ssh/id_ed25519_gh_sign_pers.age` |

## GitHub Actions

| 名称 | 発行元 | 権限・用途 | 利用場所 | 管理場所 |
|---|---|---|---|---|
| `GITHUB_TOKEN` | GitHub | workflow実行中のGitHub API操作。runtime専用 | GitHub Actions実行中 | GitHubが実行時に自動提供 |

- 手動credentialは発行元で更新・失効し、agenixは新しい暗号文をYubiKeyで作成してHome Managerを再実行する。
- GitHub Actions Secretを`FLAKE_UPDATE_TOKEN`から`AUTOMATION_TOKEN`へ手動renameし、影響するworkflow実行前に切り替える。
- R2は新世代作成、active切替、動作確認、旧世代削除の順でローテーションする。`GITHUB_TOKEN`はGitHubが管理する。

## 環境変数

- 各環境secretは、ファイル名から`.age`を除き、大文字化して`_`区切りにした名前で環境変数へ公開する。

| 名称 | 発行元 | 権限・用途 | 利用場所 | 管理場所 |
|---|---|---|---|---|
| `gemini-api-key.age` | ユーザー | Gemini APIの認証 | Home Manager管理の環境変数 | `secrets/env/gemini-api-key.age` |
| `gh-token.age` | ユーザー | GitHub APIの認証 | Home Manager管理の環境変数 | `secrets/env/gh-token.age` |
| `mem0-api-key.age` | ユーザー | Mem0 APIの認証 | Home Manager管理の環境変数 | `secrets/env/mem0-api-key.age` |
| `nvidia-api-key.age` | ユーザー | NVIDIA APIの認証 | Home Manager管理の環境変数 | `secrets/env/nvidia-api-key.age` |
| `opencode-go-api-key.age` | ユーザー | OpenCode Go providerの認証 | Home Manager管理の環境変数 | `secrets/env/opencode-go-api-key.age` |
| `openrouter-api-key.age` | ユーザー | OpenRouter providerの認証 | Home Manager管理の環境変数 | `secrets/env/openrouter-api-key.age` |
| `skillsmp-api-key.age` | ユーザー | SkillsMP MCPの認証 | Home Manager管理の環境変数 | `secrets/env/skillsmp-api-key.age` |
