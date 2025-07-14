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