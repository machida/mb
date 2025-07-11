# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create initial site settings
SiteSetting.set('site_title', 'マチダのブログ')
SiteSetting.set('top_page_description', 'マチダのブログへようこそ。技術やライフスタイルについて書いています。')
SiteSetting.set('default_og_image', 'https://example.com/default-og-image.jpg')
SiteSetting.set('copyright', '© 2025 マチダのブログ. All rights reserved.')

puts "初期サイト設定を作成しました！"

# Create admin user
Admin.find_or_create_by!(email: 'admin@example.com') do |admin|
  admin.user_id = 'admin'
  admin.password = 'admin123'
  admin.password_confirmation = 'admin123'
end

# Create sample articles for design customization
sample_articles = [
  {
    title: "Rails 8.0の新機能を試してみた",
    summary: "Rails 8.0で追加された新機能を実際に使ってみた感想とコードサンプルを紹介します。",
    body: <<~MARKDOWN,
      # Rails 8.0の新機能について

      Rails 8.0がリリースされました！今回のアップデートでは、以下の新機能が追加されています。

      ## 主な新機能

      ### 1. パフォーマンスの向上
      - データベースクエリの最適化
      - レスポンス時間の短縮
      - メモリ使用量の削減

      ### 2. 新しいヘルパーメソッド
      ```ruby
      # 新しいヘルパーの例
      def format_date(date)
        date.strftime("%Y年%m月%d日")
      end
      ```

      ### 3. セキュリティ強化
      - CSRF対策の改善
      - XSS対策の強化
      - SQLインジェクション対策

      ## 実際に使ってみた感想

      新機能を使ってみたところ、特にパフォーマンスの向上が顕著でした。
      データベースアクセスが20%程度高速化され、ユーザー体験が大幅に改善されています。

      ## まとめ

      Rails 8.0は実用的なアップデートが多く、プロダクションでも安心して使えそうです。
      皆さんもぜひ試してみてください！
    MARKDOWN
    author: "machida",
    draft: false,
    created_at: 2.days.ago,
    updated_at: 2.days.ago
  },
  {
    title: "Tailwind CSSでモダンなUIを作る方法",
    summary: "Tailwind CSSを使用してモダンで美しいUIを作成するためのベストプラクティスを解説します。",
    body: <<~MARKDOWN,
      # Tailwind CSSでモダンなUIを作る

      Tailwind CSSは、ユーティリティファーストのCSSフレームワークです。

      ## 基本的な使い方

      ### レスポンシブデザイン
      ```html
      <div class="w-full md:w-1/2 lg:w-1/3">
        <p class="text-sm md:text-base lg:text-lg">
          レスポンシブなテキスト
        </p>
      </div>
      ```

      ### カラーパレット
      - `bg-blue-500` - 青色の背景
      - `text-gray-700` - グレーのテキスト
      - `border-green-300` - 緑色のボーダー

      ## コンポーネントの作成

      ### カードコンポーネント
      ```html
      <div class="bg-white rounded-lg shadow-md p-6">
        <h2 class="text-xl font-bold mb-4">カードタイトル</h2>
        <p class="text-gray-600">カードの内容...</p>
      </div>
      ```

      ### ボタンコンポーネント
      ```html
      <button class="bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded">
        クリック
      </button>
      ```

      ## パフォーマンス最適化

      1. **PurgeCSS**を使用して未使用のCSSを削除
      2. **JIT mode**でビルド時間を短縮
      3. **Component extraction**で再利用性を向上

      Tailwind CSSを使うことで、効率的かつ美しいUIを構築できます。
    MARKDOWN
    author: "machida",
    draft: false,
    created_at: 5.days.ago,
    updated_at: 5.days.ago
  },
  {
    title: "JavaScript最新機能まとめ",
    summary: "ES2023で追加された最新のJavaScript機能を実例とともに紹介します。",
    body: <<~MARKDOWN,
      # JavaScript最新機能まとめ

      ES2023で追加された新機能をまとめました。

      ## 新機能一覧

      ### 1. Array.prototype.toSpliced()
      ```javascript
      const arr = [1, 2, 3, 4, 5];
      const newArr = arr.toSpliced(2, 1, 'inserted');
      console.log(newArr); // [1, 2, 'inserted', 4, 5]
      console.log(arr); // [1, 2, 3, 4, 5] (元の配列は変更されない)
      ```

      ### 2. Array.prototype.toReversed()
      ```javascript
      const arr = [1, 2, 3];
      const reversed = arr.toReversed();
      console.log(reversed); // [3, 2, 1]
      console.log(arr); // [1, 2, 3] (元の配列は変更されない)
      ```

      ### 3. Array.prototype.toSorted()
      ```javascript
      const arr = [3, 1, 2];
      const sorted = arr.toSorted();
      console.log(sorted); // [1, 2, 3]
      console.log(arr); // [3, 1, 2] (元の配列は変更されない)
      ```

      ## 実用的な使用例

      ### データ処理パイプライン
      ```javascript
      const processData = (data) => {
        return data
          .toSorted((a, b) => a.id - b.id)
          .toSpliced(0, 1) // 最初の要素を削除
          .map(item => ({ ...item, processed: true }));
      };
      ```

      これらの新機能により、イミュータブルなデータ操作がより簡単になりました。
    MARKDOWN
    author: "machida",
    draft: false,
    created_at: 1.week.ago,
    updated_at: 1.week.ago
  },
  {
    title: "開発効率を上げるVSCodeの設定",
    summary: "VSCodeの設定をカスタマイズして開発効率を大幅に向上させる方法を紹介します。",
    body: <<~MARKDOWN,
      # 開発効率を上げるVSCodeの設定

      VSCodeの設定をカスタマイズして、開発効率を向上させましょう。

      ## 必須拡張機能

      ### 1. プログラミング言語
      - **Ruby** - Ruby言語サポート
      - **JavaScript (ES6) code snippets** - JSスニペット
      - **HTML CSS Support** - HTML/CSSサポート

      ### 2. 開発支援
      - **GitLens** - Git履歴の可視化
      - **Prettier** - コードフォーマッター
      - **ESLint** - JavaScriptリンター

      ### 3. 効率化
      - **Auto Rename Tag** - HTMLタグの自動リネーム
      - **Bracket Pair Colorizer** - 括弧の色分け
      - **Indent Rainbow** - インデントの可視化

      ## settings.jsonの設定

      ```json
      {
        "editor.fontSize": 14,
        "editor.tabSize": 2,
        "editor.insertSpaces": true,
        "editor.formatOnSave": true,
        "files.autoSave": "afterDelay",
        "files.autoSaveDelay": 1000,
        "workbench.colorTheme": "One Dark Pro",
        "editor.minimap.enabled": false
      }
      ```

      ## キーボードショートカット

      ### よく使うショートカット
      - `Cmd + Shift + P` - コマンドパレット
      - `Cmd + P` - ファイル検索
      - `Cmd + Shift + F` - 全体検索
      - `Cmd + D` - 複数選択
      - `Alt + ↑/↓` - 行の移動

      これらの設定により、開発効率が大幅に向上します！
    MARKDOWN
    author: "machida",
    draft: false,
    created_at: 10.days.ago,
    updated_at: 10.days.ago
  },
  {
    title: "Ruby on Railsのベストプラクティス",
    summary: "長年のRails開発経験から得られたベストプラクティスとアンチパターンを紹介します。",
    body: <<~MARKDOWN,
      # Ruby on Railsのベストプラクティス

      Railsアプリケーションの品質を向上させるためのベストプラクティスをまとめました。

      ## コードの構造化

      ### 1. Fat ModelよりもService Object
      ```ruby
      # Bad
      class User < ApplicationRecord
        def send_welcome_email_and_create_profile
          # 複雑な処理...
        end
      end

      # Good
      class UserRegistrationService
        def initialize(user)
          @user = user
        end

        def call
          send_welcome_email
          create_profile
        end

        private

        def send_welcome_email
          # メール送信処理
        end

        def create_profile
          # プロフィール作成処理
        end
      end
      ```

      ### 2. 適切なバリデーション
      ```ruby
      class Article < ApplicationRecord
        validates :title, presence: true, length: { maximum: 255 }
        validates :body, presence: true
        validates :author, presence: true
        validates :summary, length: { maximum: 500 }
      end
      ```

      ## データベース設計

      ### インデックスの活用
      ```ruby
      class AddIndexToArticles < ActiveRecord::Migration[8.0]
        def change
          add_index :articles, :created_at
          add_index :articles, [:author, :draft]
        end
      end
      ```

      ### N+1問題の回避
      ```ruby
      # Bad
      articles = Article.all
      articles.each { |article| puts article.comments.count }

      # Good
      articles = Article.includes(:comments)
      articles.each { |article| puts article.comments.count }
      ```

      ## セキュリティ

      ### 1. Strong Parameters
      ```ruby
      def article_params
        params.require(:article).permit(:title, :body, :summary)
      end
      ```

      ### 2. CSRF対策
      ```ruby
      class ApplicationController < ActionController::Base
        protect_from_forgery with: :exception
      end
      ```

      ## テスト

      ### 1. 適切なテストカバレッジ
      - モデルテスト: バリデーション、メソッドの動作
      - コントローラーテスト: HTTPレスポンス、認証
      - システムテスト: ユーザーの操作フロー

      ### 2. ファクトリーの活用
      ```ruby
      FactoryBot.define do
        factory :article do
          title { "Sample Article" }
          body { "Sample body content" }
          author { "test_user" }
          draft { false }
        end
      end
      ```

      これらのベストプラクティスを実践することで、保守性の高いRailsアプリケーションを構築できます。
    MARKDOWN
    author: "machida",
    draft: false,
    created_at: 2.weeks.ago,
    updated_at: 2.weeks.ago
  },
  {
    title: "来週のリリース予定について",
    summary: "来週リリース予定の新機能と改善点について詳しく説明します。",
    body: <<~MARKDOWN,
      # 来週のリリース予定について

      来週のリリースに向けて、新機能の開発を進めています。

      ## 新機能

      ### 1. ユーザー通知機能
      - リアルタイム通知
      - メール通知設定
      - 通知履歴の確認

      ### 2. 記事の検索機能
      - 全文検索
      - タグ検索
      - 作成日での絞り込み

      ### 3. ソーシャルログイン
      - GitHub認証
      - Google認証
      - Twitter認証

      ## 改善点

      ### パフォーマンス向上
      - データベースクエリの最適化
      - キャッシュの活用
      - 画像の最適化

      ### UI/UXの改善
      - レスポンシブデザインの対応
      - ダークモードの追加
      - アクセシビリティの向上

      ## 今後の予定

      1. **来週** - 新機能のリリース
      2. **再来週** - バグ修正とパフォーマンス調整
      3. **来月** - モバイルアプリの開発開始

      ※この記事は下書きです。リリース前に内容を確認してください。
    MARKDOWN
    author: "machida",
    draft: true,
    created_at: 1.day.ago,
    updated_at: 1.day.ago
  }
]

sample_articles.each do |article_data|
  Article.find_or_create_by(title: article_data[:title]) do |article|
    article.summary = article_data[:summary]
    article.body = article_data[:body]
    article.author = article_data[:author]
    article.draft = article_data[:draft]
    article.created_at = article_data[:created_at]
    article.updated_at = article_data[:updated_at]
  end
end

puts "初期データの作成が完了しました！"
puts "Admin: admin@example.com / admin123"
puts "Articles: #{Article.count}件の記事が作成されました"
puts "Published: #{Article.published.count}件"
puts "Drafts: #{Article.drafts.count}件"
