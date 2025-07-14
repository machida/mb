# マチダのブログ

Rails 8.0.2で作成されたブログアプリケーション

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

### 1. 依存関係のインストール

```bash
bundle install
npm install
```

### 2. データベースの設定

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

- メールアドレス: `admin@example.com`
- パスワード: `admin123`

## 環境別の画像保存先

- **開発環境**: `public/uploads/images/` (ローカル)
- **本番環境**: Google Cloud Storage

## 技術スタック

- Ruby 3.4.2
- Rails 8.0.2
- SQLite3 (開発環境)
- Tailwind CSS v4.x
- Stimulus (Hotwire)
- Turbo (Hotwire)
- Redcarpet (Markdown)
- Google Cloud Storage

### テスト
- Mini-test (システムテスト、コントローラーテスト)
- Capybara + Selenium WebDriver (現在のE2E)
- Playwright (将来のE2E、実験的)

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

## トラブルシューティング

### Playwrightエラー
Playwrightでタイムアウトエラーが発生する場合：

```bash
# ブラウザの再インストール
npx playwright install --force

# 環境のクリーンアップ
rm -rf node_modules/.cache
npm install
```

詳細なエラー情報は `CLAUDE.md` の「Playwright移行計画」を参照してください。