# mb/ プロジェクト Claude 指示

## プロジェクト概要
マチダのブログシステム - Rails 7.2.2 + Ruby 3.4.2

## CSS/HTMLクラス命名規則
- `.a--` - アクション用クラス（ボタン、リンクなど）
- `.spec--` - テスト用クラス（テストでの要素選択用）

## テストコマンド
- `bundle exec rails test:all` - 全テスト実行
- テストファイルは`test/`ディレクトリ内
- システムテストとコントローラーテストを含む
- **テストフレームワーク: mini-test（RSpecではない）**
- **E2Eテスト: 現在Capybara + Selenium、将来的にPlaywrightへ移行予定**

## 開発コマンド
- `bin/dev` - 開発サーバー起動（Procfile.devを使用）
- `bin/setup` - 初期セットアップ

## 重要な注意事項
- テストファイルでは必ず`.spec--`クラスを使用してHTML要素を選択
- HTML/ERBファイルでは対応するクラス名を使用
- CSS変更時は対応するテストファイルも更新が必要
- テストセレクターは`test/support/selectors.rb`に定数として定義済み
- `_untrack/`ディレクトリ内のファイルは変更しない
- **Git pushの前に必ず`bundle exec rails test:all`を実行してテストが通ることを確認**
- **CSSファイル内の2行以上の空行は1行にまとめる（フォーマットルール）**
- **バグ修正時は必ずテストも追加する（再発防止のため）**

## テスト設定
- **テスト用パスワードは環境変数で設定可能（セキュリティ向上）**
  - `TEST_ADMIN_PASSWORD` - テスト用管理者パスワード（デフォルト: test_secure_password_test）
  - `TEST_ADMIN_EMAIL` - テスト用管理者メール（デフォルト: admin@example.com）
  - `TEST_ADMIN_USER_ID` - テスト用管理者ID（デフォルト: admin123）
- 設定は`test/test_helper.rb`の`TestConfig`モジュールで管理

## ファイル構成
- `app/views/` - ERBテンプレート
- `app/assets/stylesheets/` - CSSファイル
- `test/system/` - システムテスト
- `test/controllers/` - コントローラーテスト
- `test/support/selectors.rb` - テスト用セレクター定数

## Partialファイルの配置ルール
- `app/views/public/` - Publicレイアウトでのみ使用するpartial
- `app/views/admin/` - Adminレイアウトでのみ使用するpartial  
- `app/views/shared/` - 両方のレイアウトで共通使用するpartial

**例:**
- `app/views/public/_header.html.erb` - Public用ヘッダー
- `app/views/admin/_header.html.erb` - Admin用ヘッダー
- `app/views/shared/_toasts.html.erb` - 共通のトースト通知

## Playwright移行計画

### 現状
- E2Eテスト: Capybara + Selenium WebDriver
- 184テスト中、システムテストは約20テスト
- 一部のテストでflakyな動作（sleep使用、要素可視性問題）

### Playwright導入準備
- ✅ playwright-ruby-client gem追加
- ✅ @playwright/test npm package追加
- ✅ Playwrightブラウザインストール済み
- ✅ ApplicationPlaywrightTestCase基底クラス作成
- ❌ playwright-ruby-client初期化で技術的問題発生

### 技術的課題
- `playwright-ruby-client` gem (v1.52.0) でブラウザ起動時にtimeoutエラー
- Ruby APIの一部メソッドが期待通りに動作しない
- セットアップの複雑さにより初期実装が困難

### エラーハンドリング改善
- ✅ ApplicationPlaywrightTestCaseにタイムアウト対応実装済み
- 3回のリトライとエクスポネンシャルバックオフ
- 部分的な初期化失敗時の安全なクリーンアップ
- PlaywrightSetupError例外による詳細なエラー情報
- Rails.loggerによる詳細なデバッグログ

### 代替アプローチ（検討中）
1. **Node.js Playwright**: JavaScript版Playwrightを別プロセスで実行
2. **Capybara改善**: 現在のCapybaraテストのflaky部分を修正
3. **他のE2Eツール**: Cypress、Puppeteer等の検討
4. **playwright-ruby-client更新待ち**: gem更新での改善を待つ

### 移行手順（将来実装）
1. **技術調査**: より安定したPlaywright Ruby統合方法の調査
2. **段階的移行**: 最も不安定なテストから優先的に移行
3. **並行運用**: 移行期間中はCapybaraとPlaywrightを併用
4. **セレクター統一**: 既存の`.spec--`クラスをPlaywrightでも使用
5. **CI/CD対応**: GitHub Actionsでのplaywright実行環境整備

### Playwrightの利点
- より安定したE2Eテスト（sleep不要）
- 高速な実行速度
- 詳細なデバッグ情報とスクリーンショット
- 複数ブラウザでの並列実行