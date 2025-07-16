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

### セットアップ
- `bin/setup` - 完全セットアップ（推奨）
- `bin/quick-setup` - 最小限セットアップ
- `bin/dev-help` - 開発者向けヘルプ表示

### 開発サーバー
- `bin/dev` - 開発サーバー起動（Procfile.devを使用）
- `bin/setup --skip-server` - サーバー起動をスキップしてセットアップ

## 重要な注意事項
- テストファイルでは必ず`.spec--`クラスを使用してHTML要素を選択
- HTML/ERBファイルでは対応するクラス名を使用
- CSS変更時は対応するテストファイルも更新が必要
- テストセレクターは`test/support/selectors.rb`に定数として定義済み
- `_untrack/`ディレクトリ内のファイルは変更しない
- **Git pushの前に必ず`bundle exec rails test:all`を実行してテストが通ることを確認**
- **CSSファイル内の2行以上の空行は1行にまとめる（フォーマットルール）**
- **バグ修正時は必ずテストも追加する（再発防止のため）**

## 開発ルール
- **うまくいかなかったら公式ドキュメントを確認してから行動する（勝手に予測して作業しない）**
- **コードには How**（どのように実装するか）
- **テストコードには What**（何をテストするか）
- **コミットログには Why**（なぜ変更するか）
- **コードコメントには Why not**（なぜこの方法でないか）
- **ファイルの最後に空行を入れる**

## Git ワークフロー
- **mainブランチに戻った際は必ず`git pull`を実行して最新の状態にする**
- **feature/作業内容でブランチを切って作業する**
- **作業完了後はpushしてプルリクエストを作成する**

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

### 移行手順（完了）
1. **技術調査**: ✅ より安定したPlaywright Ruby統合方法の調査完了
2. **段階的移行**: ✅ 全システムテストのPlaywright移行完了
   - ✅ `admin_dropdown_test.rb` のPlaywright版作成完了
   - ✅ `simple_dropdown_test.rb` の移行完了
   - ✅ `dropdown_turbo_navigation_test.rb` の移行完了
   - ✅ `copyright_rewrite_bug_test.rb` の移行完了
   - ✅ `copyright_edge_cases_test.rb` の移行完了
   - ✅ `copyright_update_test.rb` の移行完了
   - ✅ `admin_site_settings_test.rb` の移行完了
   - ✅ `admin_profile_test.rb` の移行完了
   - ✅ `articles_test.rb` の移行完了
   - ✅ `admin_passwords_test.rb` の移行完了
3. **並行運用**: ✅ 移行完了により単一テストフレームワークに統一
4. **セレクター統一**: ✅ 既存の`.spec--`クラスをPlaywrightでも使用
5. **CI/CD対応**: ⏳ GitHub Actionsでのplaywright実行環境整備予定

### 移行済みテスト

#### ドロップダウン関連テスト（最優先移行完了）
- ✅ `test/system/admin_dropdown_playwright_test.rb` (新規作成)
  - 元: `admin_dropdown_test.rb` (4テストケース、sleep 0.2-0.3秒、execute_script使用)
  - 改善: sleep不要、wait_for_function使用、execute_script不要
- ✅ `test/system/simple_dropdown_playwright_test.rb` (新規作成)
  - 元: `simple_dropdown_test.rb` (2テストケース、sleep 0.1秒)
  - 改善: wait_for_function使用で確実な状態確認
- ✅ `test/system/dropdown_turbo_navigation_playwright_test.rb` (新規作成)
  - 元: `dropdown_turbo_navigation_test.rb` (3テストケース、sleep 0.2-0.5秒)
  - 改善: Turboナビゲーション対応、data-dropdown-initialized属性確認

#### 著作権関連テスト（移行完了）
- ✅ `test/system/copyright_rewrite_bug_playwright_test.rb` (新規作成)
  - 元: `copyright_rewrite_bug_test.rb` (3テストケース、sleep 0.5-1秒、execute_script使用)
  - 改善: ネットワークイベント監視、wait_for_load_state使用
- ✅ `test/system/copyright_edge_cases_playwright_test.rb` (新規作成)
  - 元: `copyright_edge_cases_test.rb` (6テストケース、sleep 1秒)
  - 改善: wait_for_load_state('networkidle')使用で確実な状態確認
- ✅ `test/system/copyright_update_playwright_test.rb` (新規作成)
  - 元: `copyright_update_test.rb` (6テストケース、sleep 1秒)
  - 改善: wait_for_load_state('networkidle')使用、フッター表示確認改善

#### 管理画面テスト（移行完了）
- ✅ `test/system/admin_site_settings_playwright_test.rb` (新規作成)
  - 元: `admin_site_settings_test.rb` (4テストケース、visible: false使用)
  - 改善: visible?メソッドによる正確な可視性確認
- ✅ `test/system/admin_profile_playwright_test.rb` (新規作成)
  - 元: `admin_profile_test.rb` (5テストケース、visible: false使用)
  - 改善: HTML5バリデーション状態の正確な確認
- ✅ `test/system/admin_passwords_playwright_test.rb` (新規作成)
  - 元: `admin_passwords_test.rb` (7テストケース)
  - 改善: 統一されたテストフレームワークによる保守性向上

#### コンテンツ管理テスト（移行完了）
- ✅ `test/system/articles_playwright_test.rb` (新規作成)
  - 元: `articles_test.rb` (9テストケース)
  - 改善: より安定したページ遷移、要素確認の改善

#### 移行による改善点
- **安定性向上**: sleep代わりにwait_for_function、wait_for_load_state使用
- **実行時間短縮**: 固定待機時間なし、条件満足次第即座に継続
- **保守性向上**: より明示的な状態確認とエラーメッセージ
- **Turbo対応**: JavaScript再初期化の適切な検出
- **ネットワーク監視**: execute_script代わりにネットワークイベント監視
- **デバッグ改善**: Rails.logger使用、puts代わりの構造化ログ

#### 移行状況
- **完了**: 10ファイル（39テストケース）の完全移行完了 🎉
- **統一**: 単一テストフレームワーク（Playwright）による保守性向上
- **効果**: 全システムテストの安定性向上と開発効率の改善

#### 移行の意義
- **保守性**: 複数テストフレームワーク併用の複雑さを解消
- **一貫性**: 統一された待機戦略とエラーハンドリング
- **将来性**: Playwrightの継続的な改善によるメリット享受

### Playwrightの利点
- より安定したE2Eテスト（sleep不要）
- 高速な実行速度
- 詳細なデバッグ情報とスクリーンショット
- 複数ブラウザでの並列実行