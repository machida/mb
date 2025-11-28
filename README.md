# マチダのブログ

![CI](https://github.com/machida/mb/actions/workflows/ci.yml/badge.svg)
[![Coverage Status](https://coveralls.io/repos/github/machida/mb/badge.svg?branch=main)](https://coveralls.io/github/machida/mb?branch=main)
![Ruby 3.4.5](https://img.shields.io/badge/Ruby-3.4.5-red.svg)
![Node.js 20](https://img.shields.io/badge/Node.js-20.x-339933.svg)
![License](https://img.shields.io/github/license/machida/mb)

Rails 8.0.3で作成されたブログアプリケーション

## 機能

- 記事の作成・編集・削除（管理者のみ）
- Markdown記法での記事作成
- リアルタイムプレビュー
- 下書き保存機能
- 画像のドラッグ&ドロップアップロード
- 記事の年別・月別アーカイブ
- 管理者認証
- トースト通知

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

## 複数ブランチでの同時開発

このプロジェクトでは[Phantom](https://github.com/aku11i/phantom)を使用して複数のブランチで同時に開発することができます。

### Phantomのセットアップ

```bash
# Homebrewでインストール（推奨）
brew install aku11i/tap/phantom

# または npm でインストール
npm install -g @aku11i/phantom
```

### 基本的な使い方

```bash
# 新しいブランチでワークツリーを作成
phantom create feature/new-feature

# 既存のブランチにアタッチ
phantom attach existing-branch

# ワークツリー一覧表示
phantom list

# 特定のワークツリーでコマンド実行
phantom exec feature/new-feature npm run build

# ワークツリーでシェルを開く
phantom shell feature/new-feature

# ワークツリーを削除
phantom delete feature/new-feature
```

### 実際の開発フロー

```bash
# 1. 新機能のワークツリーを作成
phantom create feature/user-auth

# 2. 別のワークツリーでバグ修正
phantom create fix/login-issue

# 3. メインのワークツリーで開発サーバーを起動
bin/dev

# 4. 別のワークツリーでテストを実行
phantom exec feature/user-auth bundle exec rails test

# 5. 完了したらワークツリーを削除
phantom delete feature/user-auth
```

各ワークツリーは独立したディレクトリで管理され、異なるブランチで同時に作業できます。

## 管理者ログイン

### 初期ユーザー情報
- **メールアドレス**: `admin@example.com`
- **ユーザーID**: `admin`
- **パスワード**: `admin123`

> **⚠️ 重要なセキュリティ注意事項**
> 
> **本番環境デプロイ後は必ずパスワードを変更してください**
> 
> 1. 管理画面にログイン後、プロフィール編集画面からパスワードを変更
> 2. 開発用の初期パスワード `admin123` は安全ではありません
> 3. 強力なパスワード（8文字以上、英数字記号混在）を設定してください

## 環境別の画像保存先

- **開発環境**: `public/uploads/images/` (ローカル)
- **本番環境**: Google Cloud Storage

## 技術スタック

- Ruby 3.4.5
- Rails 8.0.3
- SQLite3 (開発環境)
- Tailwind CSS v4.x
- 独自のCSSカスタムプロパティ（`--app-spacing-*`, `@custom-media --breakpoint-*`）で余白・ブレークポイントを一元管理
- Stimulus (Hotwire)
- Turbo (Hotwire)
- Redcarpet (Markdown)
- Google Cloud Storage

### テスト
- Mini-test (システムテスト、コントローラーテスト)
- Playwright 1.55.0 (E2E テスト、完全移行済み)
- playwright-ruby-client 1.55.0

## 機能詳細

### 記事管理
- 管理者のみが記事を作成・編集・削除可能
- Markdown記法での記事作成
- リアルタイムプレビュー機能
- 下書き保存と公開の切り替え

### 画像アップロード
- ドラッグ&ドロップによる画像アップロード
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
npm install @playwright/test@1.55.0

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
- **Playwright**: 1.55.0（推奨）
- **playwright-ruby-client**: 1.55.0（最新安定版）
- これらの組み合わせで最適な動作を確認済み
