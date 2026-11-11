# マチダのブログ

![CI](https://github.com/machida/mb/actions/workflows/ci.yml/badge.svg)
[![Coverage Status](https://coveralls.io/repos/github/machida/mb/badge.svg?branch=main)](https://coveralls.io/github/machida/mb?branch=main)
![License](https://img.shields.io/github/license/machida/mb)
![Ruby 4.0.9](https://img.shields.io/badge/Ruby-4.0.9-red.svg)
![Node.js 26.13.0](https://img.shields.io/badge/Node.js-26.13.0-339933.svg)

Rails 8.1.4.1で作成されたブログアプリケーション

## 機能

- 記事の作成・編集・削除（管理者のみ）
- Markdown記法での記事作成
- リアルタイムプレビュー
- 下書き保存機能
- 画像のドラッグ&ドロップアップロード
- **画像クロップ機能**（アップロード前にトリミング可能、16:9や1200:630の縦横比対応）
- 記事の年別・月別アーカイブ
- 管理者認証
- トースト通知

## セキュリティチェック

CIで次の検査を実行します。DependabotはGem・npm・GitHub Actionsの更新を毎日確認します。

Coverallsの配布ファイル取得にはHTTPエラー検知と最大3回の再試行を設定しています。継続的な障害時もチェックサム検証を省略せず、CIを失敗させます。詳細は[運用Runbook](docs/operations.md#ciのcoverallsダウンロード障害)を参照してください。

```bash
bundle exec bundler-audit check --update
bundle exec brakeman --no-pager
npm audit
```

## セットアップ

### 🚀 ワンコマンドセットアップ（推奨）

```bash
bin/setup
```

完全な開発環境セットアップを自動実行します：
- Ruby/Node.js の依存関係インストール
- データベース準備・マイグレーション・シード
- Playwright E2E テストの設定
- アセット事前コンパイル
- 開発サーバーの起動

### ⚡ クイックセットアップ

```bash
bin/quick-setup
```

最小限のセットアップのみ実行します（Playwright なし）。

### 🔧 手動セットアップ

#### 1. 依存関係のインストール

```bash
bundle install
npm install
```

#### 2. データベースの設定

```bash
rails db:create
rails db:migrate
rails db:seed
```

### 3. Google Cloud Storage の設定（本番環境用）

本番環境では画像がGoogle Cloud Storageに保存されます。以下の設定が必要です：

```bash
# 認証情報を設定
rails credentials:edit
```

以下の情報を追加してください：

```yaml
gcp:
  project_id: your-gcp-project-id
  bucket: your-gcs-bucket-name
  credentials: |
    {
      "type": "service_account",
      "project_id": "your-project-id",
      "private_key_id": "your-private-key-id",
      "private_key": "-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY\n-----END PRIVATE KEY-----\n",
      "client_email": "your-service-account@your-project.iam.gserviceaccount.com",
      "client_id": "your-client-id",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/your-service-account%40your-project.iam.gserviceaccount.com"
    }
```

### メール送信の設定（本番環境用）

パスワード再設定メールはSMTPで送信します。利用者ごとに送信元とSMTPアカウントを設定してください。個人のアドレスやパスワードをソースコードに埋め込む必要はありません。

Kamalで運用する場合は、既存の本番credentialsに以下の `smtp` を追加する方法が簡単です。他の設定を消さずに編集してください。

```bash
bin/rails credentials:edit --environment production
```

```yaml
smtp:
  address: smtp.gmail.com
  port: 587
  user_name: sender@example.com
  password: YOUR_APP_PASSWORD
  from: sender@example.com
  authentication: plain
  ssl: false
```

Google Workspace / Gmailでは、送信アカウントの2段階認証を有効にし、利用可能な場合は専用のアプリパスワードを発行して `password` に指定します。通常のGoogleログイン用パスワードは使用しません。組織の設定などによりアプリパスワードを作成できない場合は、Workspace管理者にSMTPリレーなどの利用方法を確認してください。[Google公式の説明](https://support.google.com/accounts/answer/185833)

別のSMTPサービスを使う場合は、そのサービスの接続情報に置き換えてください。465番ポートの暗黙TLSを使う場合は `ssl: true` にします。

環境変数でも設定できます。空でない環境変数がcredentialsより優先されます。

| 環境変数 | credentialsのキー | 省略時 |
| --- | --- | --- |
| `SMTP_ADDRESS` | `smtp.address` | `smtp.gmail.com` |
| `SMTP_PORT` | `smtp.port` | 587（SSL有効時は465） |
| `SMTP_USER_NAME` | `smtp.user_name` | なし |
| `SMTP_PASSWORD` | `smtp.password` | なし |
| `SMTP_AUTHENTICATION` | `smtp.authentication` | `plain` |
| `SMTP_SSL` | `smtp.ssl` | `false`（STARTTLS） |
| `MAILER_FROM` | `smtp.from` | SMTPユーザー名、未設定時は `noreply@example.com` |
| `APP_HOST` | — | `example.com`（再設定URLのホスト） |

本番では `APP_HOST` を自分のドメインに設定してください。再設定URLはHTTPSで生成されます。送信元はSMTPサービスで送信を許可されたアドレスを指定します。

環境変数は実行環境に設定してください（`.env` ファイルは自動では読み込みません）。Kamalでは公開可能な設定を `config/deploy.yml` の `env.clear` に、`SMTP_USER_NAME` / `SMTP_PASSWORD` などを `env.secret` に追加し、`.kamal/secrets` で環境変数やパスワード管理ツールから取得します。credentialsを使う場合は既存の `RAILS_MASTER_KEY` の受け渡しを利用できます。

このリポジトリのGitHub Actionsデプロイでは、Repository Secretsに `SMTP_USER_NAME`、`SMTP_PASSWORD`、`MAILER_FROM` を登録してください。Kamalへ環境変数として渡し、アプリコンテナへsecretとして設定します。ローカルからKamalを実行する場合も、この3変数を設定してください。

暗号化credentialsはコミットできますが、復号鍵・平文のパスワード・環境設定ファイルはコミットしないでください。設定変更後は再デプロイが必要です。開発環境では外部に送信せず、`/letter_opener` でメールを確認します。

### 4. E2Eテスト環境の設定（Playwright）

```bash
# Playwrightブラウザのインストール
npx playwright install
# または Bundle経由で
bundle exec playwright install

# 環境変数でテスト設定をカスタマイズ（オプション）
export TEST_ADMIN_PASSWORD="your_test_password"
export TEST_ADMIN_EMAIL="test@example.com"
export TEST_ADMIN_USER_ID="test_admin"
```

### 5. 開発サーバーの起動

```bash
bin/dev
```

## 管理者ログイン

### 初期ユーザー情報

開発環境の初回seedでは `admin@example.com` / `development-password`（ユーザーID `admin`）を作成します。

本番で管理者がまだいない場合は、初回seedを実行するプロセスに以下を環境変数として渡してください。

- `INITIAL_ADMIN_EMAIL`: 管理者のメールアドレス
- `INITIAL_ADMIN_USER_ID`: 管理者のユーザーID
- `INITIAL_ADMIN_PASSWORD`: パスワード管理ツールなどで生成した16文字以上のパスワード

GitHub Actionsからの初回デプロイでは、同名の3項目をRepository Secretsに登録します。Actions → `.kamal/secrets` → Kamalの `env.secret` → コンテナーの順で渡されます。ローカルからのKamal実行では同名の環境変数を設定してください。未設定の項目はKamalの必須シークレットに追加されないため、既存環境への通常デプロイには不要です。初期作成後はSecretsを削除して再デプロイできます。初回失敗後の復旧は [運用手順](docs/operations.md#初回seed失敗後の復旧) を参照してください。

設定不足の場合はseedのデータ作成前に停止します。既存の管理者がいる場合は追加も上書きもしません。認証情報はログに表示しません。seedはサンプル記事やサイト設定も作成するため、管理者の復旧用途には使用しないでください。

ログインは同じIPから3分間に10回、パスワード再設定メールの申請は15分間に5回までです。超過時はHTTP 429を返します。本番の制限カウンターはSolid Cacheで共有します。
パスワード変更・再設定後は他のブラウザーのセッションが無効になり、再ログインが必要です。同じブラウザーの別タブで開いた管理フォームは、Turbo送信直前に認証済みセッションのCSRFトークンを取得し直すため、入力を保持したまま保存できます。この変更の初回デプロイ時も既存セッションは再ログインが必要です。

Markdownは危険なプロトコルのリンクを出力せず、コードブロックの言語指定をHTMLエスケープします。

## 環境別の画像保存先

- **開発環境**: `public/uploads/images/` (ローカル)
- **本番環境**: Google Cloud Storage

## 技術スタック

- Ruby 4.0.9 / Bundler 4.0.23
- Node.js 26.13.0 LTS（`.node-version`）
- Rails 8.1.4.1
- SQLite3（開発・テスト・本番。本番はKamalの永続ボリュームに保存）
- Tailwind CSS v4.x
- 独自のCSSカスタムプロパティ（`--app-spacing-*`, `@custom-media --breakpoint-*`）で余白・ブレークポイントを一元管理
- Stimulus (Hotwire)
- Turbo (Hotwire)
- Redcarpet (Markdown)
- Google Cloud Storage
- Cropper.js 2.3.1（画像クロップ、Web Components）。`npm ci` / `npm install` のpostinstallで配布ESMを `vendor/javascript/cropperjs.js` に同期します。

### テスト
- Mini-test (システムテスト、コントローラーテスト)
- Playwright 1.46.0（互換性のため固定）
- playwright-ruby-client 1.57.1

### 開発ツール
- ESLint 9.39.2（Flat Config形式）
- Prettier 3.7.4
- globals 17.0.0（ESLint用ブラウザ環境サポート）

## 機能詳細

### 記事管理
- 管理者のみが記事を作成・編集・削除可能
- Markdown記法での記事作成
- リアルタイムプレビュー機能
- 下書き保存と公開の切り替え

### 画像アップロード
- ドラッグ&ドロップによる画像アップロード
- アップロード前の画像クロップ機能（Cropper.js）
  - ヒーロー背景画像: 16:9の縦横比でトリミング
  - OGサムネイル画像: 1200:630の縦横比でトリミング
- 自動WebP変換・圧縮（品質70-75%、メタデータ削除）
- 自動的なMarkdown記法での挿入
- 画像形式とサイズの自動検証

### アーカイブ機能
- 年別・月別でのアーカイブ表示
- 記事数の表示

### 認証機能
- 管理者用のシンプルな認証システム
- セッション管理

## テスト実行

### 全テスト実行
```bash
bundle exec rails test:all
```

### システムテストのみ実行
```bash
bundle exec rails test:system
```

### テスト設定
- テスト用パスワードは環境変数で変更可能
- デフォルト値: `test_secure_password_test`
- 詳細は `test/test_helper.rb` の `TestConfig` を参照

### テスト結果
- **総テスト数**: 225テスト
- **アサーション数**: 649アサーション
- **成功率**: 100%（全テスト通過確認済み）

### テストカバレッジ
- **コントローラーテスト**: 管理機能、認証、記事管理
- **モデルテスト**: バリデーション、ビジネスロジック
- **システムテスト**: E2E全体フロー（Playwright）
- **セキュリティテスト**: ロボットヘッダー、認証機能

## 運用・本番デプロイ

本番環境へのデプロイは Kamal を使用します。本番の障害対応（502復旧）・再発防止策（スワップ、監視＋自己修復、メモリ上限、jemalloc）は運用 Runbook にまとめています。

- 運用 Runbook: [`docs/operations.md`](docs/operations.md)
- 監視＋自己修復スクリプト: [`ops/health-check.sh`](ops/health-check.sh)（サーバ上で cron 実行）

## セキュリティ

### 管理画面の保護
管理画面は以下の方法で検索エンジンからの発見を防いでいます：

- **robots.txt**: `/admin/` パスの明示的ブロック
- **HTMLメタタグ**: noindex, nofollow, noarchive 等の包括的タグ
- **HTTPヘッダー**: X-Robots-Tag ヘッダーによる追加保護

### 注意事項
- 本番環境では初期管理者パスワードを必ず変更してください
- HTTPS環境での運用を強く推奨します

## トラブルシューティング

### Playwrightエラー
Playwrightでエラーが発生する場合：

```bash
# ブラウザの再インストール
bundle exec playwright install
# または強制的に再インストール
npx playwright install --force

# Node.jsパッケージの更新
npm install @playwright/test@latest

# 環境のクリーンアップ
rm -rf node_modules/.cache
npm install
```

### テストの並列実行
Playwrightテストは並列実行を無効化しています（`parallelize(workers: 1)`）。これは以下の理由によります：

- データベーストランザクションの競合回避
- セッション管理の安定化
- ブラウザリソースの適切な管理

### ライブラリバージョン互換性

#### Playwright
- **@playwright/test**: 1.46.0（固定）
- **playwright-ruby-client**: 1.57.1
- **理由**: Playwright 1.52.0以降でタイムアウト関連の互換性問題が発生するため、1.46.0で固定
- この組み合わせで安定動作を確認済み

#### JavaScript開発ツール
- **ESLint**: 10.14.0（Flat Config形式に移行済み）
- **Prettier**: 3.9.10
- **Cropper.js**: 2.3.1（jQuery依存なし、Web Components）

## デプロイ

本番環境へのデプロイは Kamal を使用します。

### 必要な GitHub Secrets

GitHub Actionsでデプロイするには、以下のSecretsを設定してください：

- `KAMAL_REGISTRY_PASSWORD`: GitHub Container Registry (ghcr.io) のアクセストークン
- `RAILS_MASTER_KEY`: `config/master.key` の内容

### デプロイ設定

- **ポート**: アプリはThruster経由でポート80で起動
- **ヘルスチェック**: `/up` エンドポイント（ポート80）
- **タイムアウト**: デプロイ300秒、ヘルスチェック180秒

### トラブルシューティング

デプロイが失敗する場合：

1. **GitHub Secretsの確認**
   - `KAMAL_REGISTRY_PASSWORD` と `RAILS_MASTER_KEY` が設定されているか確認

2. **ログの確認**
   ```bash
   kamal app logs
   ```

3. **ヘルスチェックの確認**
   - `/up` エンドポイントがポート80で応答するか確認

## ライセンス

- このリポジトリは [MIT License](LICENSE) の下で提供されています。
- 変更内容に応じて README や AGENTS.md / CLAUDE.md も必ず更新し、ドキュメントの不整合を防いでください。
