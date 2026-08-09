# Nix構成

## flakeの入口

- `flake.nix`をNixのroot entryにする。
- `flake.nix`が`outputs.nix`を読み込む。
- `outputs.nix`を実際のoutputs定義にする。

## flake-file

- flake-fileがrootの`flake.nix`を宣言・生成する。
- `nix/modules/flake-file.nix`をflake-fileの設定にする。
- rootの`flake-file.nix`を生成時のcarrierにする。
- 通常のflake評価ではrootの`flake-file.nix`を評価しない。
- `nix run .#write-flake`でrootの`flake.nix`を再生成する。
- `outputs.nix`が生成されたappsを統合するためだけにrootの`flake-file.nix`を再評価する。

## Blueprint

- `flake.nix`と`nix/modules/flake-file.nix`でBlueprintのflake入力を配線する。
- `outputs.nix`がBlueprintを`prefix = "nix/"`と対象system付きで初期化する。
- Blueprintが`nix/`以下を規約に従って発見する。
- Blueprintがホスト、モジュール、Home設定からflake outputsを組み立てる。
- `outputs.nix`がBlueprintのoutputsに独自のoutputsを追加する。
- Blueprintは評価時のdirectory-to-output mappingを担当する。
- `outputs.nix`が自動発見できないcache bootstrapとconfiguration buildを追加する。

## agenix

- `flake.nix`と`nix/modules/flake-file.nix`でagenixのflake入力を配線する。
- `nix/modules/darwin/nix-cache.nix`がagenixのDarwin system moduleを読み込む。
- `nix/modules/home/secrets.nix`がagenixのHome Manager moduleを読み込む。
- agenixが`secrets/`の暗号化ファイルを管理する。
- `age-plugin-yubikey`とYubiKey identityで暗号文を復号する。
- `nix/home/k0ch4nx/secrets.nix`が環境変数用の暗号文をHome Managerのsecretへ割り当てる。
- `nix/home/k0ch4nx/ssh.nix`がSSH用の暗号文をHome Managerの配置先へ割り当てる。
- Home Manager activationがagenixを実行し、環境secretをZsh設定へ書き込む。
- Zsh起動時に環境secretをexportする。
- WSLは永続的なagenix systemdサービスを無効にし、Home Managerの対話的activationで実行する。
- agenixはactivation時のsecret handlingを担当する。Blueprintのoutput評価とは分離する。
- 実際の鍵やsecretの値はドキュメントに記載しない。

## ホスト

- `nix/hosts/macbook-pro/`にmacOSホストを定義する。
- DarwinのシステムモジュールとHome Managerのユーザー設定を読み込む。
- `nix/hosts/ubuntu-wsl/`にWSLホストを定義する。
- system-managerのシステム設定とHome Managerのユーザー設定を読み込む。
- `outputs.nix`がホストごとのconfigurationを公開する。

## モジュール

- `nix/modules/darwin/`にDarwin共通モジュールを置く。
- `nix/modules/system-manager/`にWSLのシステム共通モジュールを置く。
- `nix/modules/home/`にHome Manager共通モジュールを置く。
- ホスト固有の設定から共通モジュールを`imports`する。

## 共通Home設定

- `nix/home/k0ch4nx/default.nix`を共通Home設定の入口にする。
- 共通のHome Managerモジュールとユーザー設定を読み込む。
- macOS固有の設定は`nix/modules/home/darwin/`に置く。
- WSL固有の設定は`nix/modules/home/wsl/`に置く。
- 各ホストのHome設定が共通設定とOS固有設定を組み合わせる。

## ライブラリとヘルパー

- `nix/r2-cache.nix`でキャッシュ設定を共有する。
- `nixpkgs.lib`の関数で属性集合や出力を組み立てる。
- モジュールの`lib`で設定の結合と評価順を制御する。
- flake-fileを生成ヘルパー、Blueprintをoutput発見ヘルパーとして使う。
