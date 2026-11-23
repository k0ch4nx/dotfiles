# 認証情報

## OpenTofu

- OpenTofu作成credentialの表示名は`tf-`で始める。手動管理credentialはprefixなし。

| 名称 | 発行元 | 権限・用途 | 利用場所 | 管理場所 |
|---|---|---|---|---|
| `CLOUDFLARE_API_TOKEN` | Cloudflare | Cloudflare providerの認証 | GitHub Actions | GitHub Actions Secrets（手動管理） |
| `NIX_CACHE_CI_PRIVATE_KEY` | cache署名鍵の管理者 | CIのNix cache署名 | GitHub Actions | GitHub Actions Secrets |
| `cloudflare_account_id` | 設定値 | Cloudflare account識別。secretではない | OpenTofu provider | `infra/dotfiles/variables.tf`のdefault |
| `bucket_name` | 設定値 | R2 cache bucket設定。secretではない | OpenTofu、Cloudflare R2 | `infra/dotfiles/variables.tf`のdefault |
| `r2_ro_access_key_id` | OpenTofuがCloudflareで作成 | RO credentialのID。Nix cache substitutionの読み取り専用 | Nix daemon | Scalr state outputからruntime取得 |
| `r2_ro_secret_access_key` | OpenTofuがCloudflareで作成 | RO credentialのsecret。Nix cache substitutionの読み取り専用 | Nix daemon | Scalr state outputからruntime取得 |
| `r2_rw_access_key_id` | OpenTofuがCloudflareで作成 | RW credentialのID。cacheの読み取り・書き込み | cache初期化・push・touch | Scalr state outputからruntime取得 |
| `r2_rw_secret_access_key` | OpenTofuがCloudflareで作成 | RW credentialのsecret。cacheの読み取り・書き込み | cache初期化・push・touch | Scalr state outputからruntime取得 |

## 手動

| 名称 | 発行元 | 権限・用途 | 利用場所 | 管理場所 |
|---|---|---|---|---|
| `AUTOMATION_TOKEN` | GitHub | GitHub provider、更新PRの認証 | GitHub Actions、OpenTofu | GitHub Actions Secrets |
| `SCALR_TOKEN` | Scalr | CIのstate読み書き・ロックとoutput取得 | GitHub Actions | GitHub Actions Repository secrets |
| `TF_TOKEN_k0ch4nx_scalr_io` | Scalr | ローカルのstate認証。CIと同じトークン | ローカルOpenTofu、bootstrap | 環境変数、またはbootstrapがYubiKeyで`secrets/auth/scalr-token.age`を復号 |
| `nix-cache-local-private-key.age` | ユーザー | local Nix cache署名 | local Nix cache | `secrets/auth/nix-cache-local-private-key.age` |

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
- `state-versions:read`はstate全体を読み取れるため、RO用outputの取得でもRW credentialを含むstateを読み取れる。信頼できる実行環境にのみScalr tokenを渡す。
- Repository secrets方式では、同一リポジトリのPRで実行されるスクリプトもsecretにアクセスできる。
- Scalr tokenの更新時は、`secrets/auth/scalr-token.age`を再暗号化し、GitHub Repository secretの`SCALR_TOKEN`も同じ値に更新する。
- Scalr側のstateが最新であることを確認してから、既存のHCP backend情報が残る作業ディレクトリは、新しい作業ディレクトリまたは`tofu init -reconfigure`でScalrに接続する。
- R2は新世代作成、active切替、動作確認、旧世代削除の順でローテーションする。`GITHUB_TOKEN`はGitHubが管理する。

## 環境変数

- 各環境secretは、ファイル名から`.age`を除き、大文字化して`_`区切りにした名前で環境変数へ公開する。

| 名称 | 発行元 | 権限・用途 | 利用場所 | 管理場所 |
|---|---|---|---|---|
| `commandcode-api-key.age` | ユーザー | CommandCode APIの認証 | Home Manager管理の環境変数 | `secrets/env/commandcode-api-key.age` |
| `deepinfra-api-key.age` | ユーザー | DeepInfra APIの認証 | Home Manager管理の環境変数 | `secrets/env/deepinfra-api-key.age` |
| `gemini-api-key.age` | ユーザー | Gemini APIの認証 | Home Manager管理の環境変数 | `secrets/env/gemini-api-key.age` |
| `gh-token.age` | ユーザー | GitHub APIの認証 | Home Manager管理の環境変数 | `secrets/env/gh-token.age` |
| `nvidia-api-key.age` | ユーザー | NVIDIA APIの認証 | Home Manager管理の環境変数 | `secrets/env/nvidia-api-key.age` |
| `opencode-api-key.age` | ユーザー | OpenCode Go providerの認証 | Home Manager管理の環境変数 | `secrets/env/opencode-api-key.age` |
| `openrouter-api-key.age` | ユーザー | OpenRouter providerの認証 | Home Manager管理の環境変数 | `secrets/env/openrouter-api-key.age` |
| `skillsmp-api-key.age` | ユーザー | SkillsMP MCPの認証 | Home Manager管理の環境変数 | `secrets/env/skillsmp-api-key.age` |
