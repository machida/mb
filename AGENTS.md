# リポジトリガイドライン

## プロジェクト概要
- マチダのブログ (Rails 8.0.3 / Ruby 3.4.5 / Node.js 22) で、MiniTest + Playwright によるE2Eで品質を担保します。
- ブラウザUIは Tailwind CSS + Stimulus + Turbo、アップロードは開発で `public/uploads/images`、本番で Google Cloud Storage を使用します。
- 既定の管理者は `admin@example.com` (`admin123`) なので、新環境ごとに必ずパスワードを変更し安全な保管場所(1Password等)に記録してください。

## メタルール
- `AGENTS.md` と `CLAUDE.md` は常に同一内容の日本語ドキュメントとして保守すること。どちらかを更新した場合は、同一コミット内で必ず他方も同じ変更を反映させる。
- 作業に入る前に必ず `AGENTS.md` と `CLAUDE.md` を読み、最新ルールを再確認してから着手する。
- すぐに解決方法がわからない問題に遭遇したら、推測で試行錯誤せず公式ドキュメントや信頼できる情報源を確認してから対応方針を決める。

## ディレクトリ構成とモジュール設計
- `app/` に Railsコード、`app/services`・`lib/` に横断的な業務ロジック、`app/components` に再利用UI、`app/javascript` に Stimulus/Turbo/ESM を配置します。
- テストは `test/` 配下（`test/system` がブラウザ系、`test/support/selectors.rb` にテストセレクタ）で管理し、`docs/` に長文ドキュメント、`db/migrate` にスキーマ変更を置きます。
- アセットとTailwind設定は `app/assets` と `config/`、`storage/` と `_untrack/` はGit管理外なので編集・コミットしないでください。
- partialは `app/views/public|admin|shared/` に用途別で配置し、肥大化したクラスは200行以下を目安に積極的に分割します。

## セットアップ & 開発コマンド
```bash
bin/setup             # Ruby/Node/DB/Playwright/seed を一括セットアップ
bin/quick-setup       # Playwrightを除外した最小セットアップ
bin/setup --skip-server # サーバー起動を省いたセットアップ
bin/dev               # Procfile.dev に基づくRails+Vite+Tailwind同時起動
bin/dev-help          # プロセス一覧とTipsを表示
bundle exec rails server   # Rails単体を起動
bundle exec foreman start  # Procfileベースに複数プロセスを起動
```
- DB操作: `rails db:create | db:migrate | db:seed | db:reset`。
- ビルド: `bin/dev` 内のVite監視、または `rails assets:precompile`、キャッシュが壊れたら `bin/rails assets:clobber`。

## テスト運用
```bash
bundle exec rails test:all                      # MiniTest全実行
bundle exec rails test --exclude "playwright"   # 非Playwrightのみ
bundle exec rails test test/system/             # システムテスト
npm run test:playwright                         # Playwright E2E
```
- 新規機能ではユニットテスト + システム or Playwright テストを用意し、失敗ケースも1件以上入れます。
- ファイル名は機能単位（例: `admin_creates_article_test.rb`）とし、`.spec--` クラスで要素を取得します。
- Playwright失敗時は `npx playwright show-report` でトレースを添付し、テスト用管理者のENV (`TEST_ADMIN_PASSWORD/EMAIL/USER_ID`) は `test/test_helper.rb` の `TestConfig` で参照します。
- フレーキーなテストはその場で安定化し、スキップで逃げないこと。

## コーディングスタイル & 命名
- Rubyは Rails Omakase RuboCop（2スペース、snake_case、`Admin::`名前空間）に従い、`bundle exec rubocop`、必要時のみ `-a`/`-A` を使用します。
- JavaScript/TypeScriptは ESLint + Prettier（2スペース、単一引用符、末尾カンマ）で整形し、Stimulusコントローラは `PascalCaseController` で1ファイル1クラスにします。
- TailwindはERBまたはViewComponentで構成し、同じユーティリティの繰り返しは `app/components` に抽出、CSSは `rem` を使い、2行以上の空行や行末スペースを除去します。

## CSS/HTMLクラス規約
- `.a--` はAtomレベルの最小パーツ、`.l--` はレイアウト、`.spec--` はテスト専用でCSSセレクタには使わないこと。
- `.spec--` クラスはPlaywright/MiniTestから参照し、追加・変更時は `test/support/selectors.rb` も更新します。

## コード品質・設計原則
- 原則: 予測しやすい / 再利用しやすい / 保守しやすい / 拡張しやすい。
- 1ファイル200行以下を目安に単一責任へ分割し、複雑な判断理由はコメントで "Why not" を補足します。
- 実装はコードで"How"、テストは"What"、コミットは"Why"を語ること。ファイル末尾に改行を入れ、トレーリングスペースは禁止。

## Git・コミット・PR ルール
- `phantom` で `feature/...` ブランチを作成し、main直コミット禁止。作業前後で `git pull --rebase origin main` を実行します。
- 作業を始める前に必ず専用ブランチを切り、mainで直接コミットしないこと。
- コミットはConventional Commits（`fix:`, `refactor:`, `docs:` 等）をベースに小さく刻み、進捗のたびにこまめに作成する。push前に `bundle exec rails test:all` と `npm run lint` を通します。
- PRには要約、実行済みコマンド、関連Issue、UI変更ならスクリーンショット/TTY記録、環境変数やマイグレーションがあれば明記します。
- READMEや依存更新を行ったときは必要に応じて本ガイドも更新します。

## Phantom ワークツリー運用
```bash
phantom create feature/new-feature
phantom attach existing-branch
phantom list
phantom exec feature/foo bundle exec rails test
phantom shell feature/foo
phantom delete feature/foo
```
- ワークツリーは `.git/phantom/worktrees` に作成され、DBは共有されるため同時マイグレーションに注意。メインディレクトリで `bin/dev` を動かし、各ワークツリーでテストを実行します。

## セキュリティ & 設定
- GCSやAPIキーは `rails credentials:edit` に保存し、`.env` やJSON鍵ファイルをコミットしないでください。新しい秘密設定はPRで必ず説明します。
- `storage/` と `public/uploads` は常に `.gitignore` されていることを確認し、アップロード系変更ではローカル・本番での保存先を明記します。
- CSSが再ビルドされない場合は `bin/rails assets:clobber && bin/dev` を実行してキャッシュをクリアします。
- バグ修正時は必ず再発防止テストを追加し、タスクはメモ化して誰でも途中から再開できる状態を保ちます。
