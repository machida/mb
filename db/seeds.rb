# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create initial site settings
SiteSetting.set('site_title', 'ブログ')
SiteSetting.set('top_page_description', '技術やライフスタイルについて書いています。')
SiteSetting.set('default_og_image', 'https://example.com/default-og-image.jpg')
SiteSetting.set('hero_background_image', '')
SiteSetting.set('hero_text_color', 'white')
SiteSetting.set('copyright', 'マチダのブログ')

puts "初期サイト設定を作成しました！"

# Create admin user
Admin.find_or_create_by!(email: 'admin@example.com') do |admin|
  admin.user_id = 'admin'
  admin.password = 'admin123'
  admin.password_confirmation = 'admin123'
end

# Create sample articles for design customization
sample_articles = [
  # ===== 公開記事 (15件) =====
  {
    title: "AIツールを使った開発効率化",
    summary: "GitHub Copilot、ChatGPT、Claude などのAIツールを日常の開発ワークフローに組み込んで感じた変化と、使いこなすためのコツをまとめました。",
    thumbnail: "https://picsum.photos/seed/ai-tools/1200/630",
    body: <<~MARKDOWN,
      最近、AIツールの活用が開発の現場でも当たり前になってきました。今回は実際に使って感じたことをまとめます。

      ![AIツールを活用した開発の様子](https://picsum.photos/seed/coding-ai/800/400)

      ## 使っているツール

      ### GitHub Copilot
      コードの補完がとにかく速い。特にボイラープレートが多い処理では体感で2〜3倍は速くなった気がします。

      ```ruby
      # こんな感じのコードをほぼ自動で生成してくれる
      def find_or_create_user(email:, name:)
        User.find_or_initialize_by(email: email).tap do |user|
          user.name = name
          user.save!
        end
      end
      ```

      ### Claude
      設計の相談やコードレビューに使っています。「このクラス、どう分割すべき？」みたいな抽象的な質問にも答えてくれるのが便利。

      ## 変わったこと

      - ドキュメントを読む時間が減った
      - 「とりあえず書いてみる」のハードルが下がった
      - 反面、生成コードをちゃんと読まないとバグを仕込みやすい

      ![コードレビューのイメージ](https://picsum.photos/seed/code-review/800/400)

      ## 注意点

      AIが生成したコードをそのまま使うのは危険です。特にセキュリティ周りやエッジケースは必ず自分で確認するようにしています。

      ツールに使われるのではなく、ツールを使いこなす側でいたいですね。
    MARKDOWN
    author: "admin",
    draft: false,
    created_at: 1.day.ago,
    updated_at: 1.day.ago
  },
  {
    title: "桜の季節の公園散歩",
    summary: "近所の公園の桜が満開になったので、朝のうちに散歩してきました。人が少ない時間帯に行くのがおすすめです。",
    thumbnail: "https://picsum.photos/seed/sakura-park/1200/630",
    body: <<~MARKDOWN,
      毎年この季節になると、早起きして公園を歩くのが楽しみになっています。

      ![満開の桜並木](https://picsum.photos/seed/cherry-blossom/800/400)

      ## 朝7時の公園

      平日の朝7時ごろはまだ人が少なく、ゆっくり歩けます。犬の散歩をしている人と、同じようにカメラを持った人がちらほら。

      桜の木の下でコーヒーを飲みながら、しばらくぼーっとしていました。こういう時間が一番好きです。

      ## 今年の桜

      今年は例年より少し早めに咲いたようで、週末には満開になっていました。風が吹くたびに花びらが舞って、なかなか幻想的な光景。

      ![花びらが舞う様子](https://picsum.photos/seed/petals/800/400)

      ## おすすめの時間帯

      - **早朝（7時前後）**: 人が少なく、光が柔らかい
      - **夕方（16〜17時）**: 西日が当たってきれい
      - **夜桜**: ライトアップされているならこれも良い

      来年もこの季節を楽しみにしています。
    MARKDOWN
    author: "admin",
    draft: false,
    created_at: 5.days.ago,
    updated_at: 5.days.ago
  },
  {
    title: "TypeScriptの型システムを深く理解する",
    summary: "TypeScriptの型システムは奥が深い。ジェネリクス、条件型、mapped typeなど、実用的なパターンを例とともに解説します。",
    thumbnail: "https://picsum.photos/seed/typescript/1200/630",
    body: <<~MARKDOWN,
      TypeScriptを使い始めてしばらく経ちますが、型システムの奥深さを最近改めて感じています。

      ## ジェネリクスの基本

      ```typescript
      function identity<T>(arg: T): T {
        return arg;
      }

      // 型推論が効く
      const result = identity("hello"); // string型
      ```

      ## 条件型 (Conditional Types)

      ```typescript
      type IsString<T> = T extends string ? true : false;

      type A = IsString<string>; // true
      type B = IsString<number>; // false
      ```

      ![TypeScriptのコード例](https://picsum.photos/seed/typescript-code/800/400)

      ## Mapped Types

      ```typescript
      type Readonly<T> = {
        readonly [P in keyof T]: T[P];
      };

      type Optional<T> = {
        [P in keyof T]?: T[P];
      };
      ```

      ## 実用的なパターン

      ### APIレスポンスの型定義

      ```typescript
      type ApiResponse<T> =
        | { status: 'success'; data: T }
        | { status: 'error'; message: string };

      async function fetchUser(id: number): Promise<ApiResponse<User>> {
        // ...
      }
      ```

      型を正しく定義しておくと、コンパイル時にバグを多く防げます。最初は面倒に感じますが、慣れると手放せなくなります。
    MARKDOWN
    author: "admin",
    draft: false,
    created_at: 2.weeks.ago,
    updated_at: 2.weeks.ago
  },
  {
    title: "自宅デスク環境を整えた",
    summary: "リモートワーク歴が長くなるにつれ、デスク環境へのこだわりも増してきました。最近の構成を紹介します。",
    thumbnail: "https://picsum.photos/seed/desk-setup/1200/630",
    body: <<~MARKDOWN,
      リモートワークを始めてから3年以上経ち、デスク環境も少しずつ育ってきました。

      ![現在のデスク環境](https://picsum.photos/seed/desk-top/800/400)

      ## 現在の構成

      | アイテム | 製品 |
      |---|---|
      | モニター | LG 27インチ 4K |
      | キーボード | HHKB Professional Hybrid |
      | マウス | Logicool MX Master 3 |
      | チェア | Herman Miller Aeron |
      | デスクライト | BenQ ScreenBar Plus |

      ## 特にこだわったもの

      ### チェア
      最初は安いチェアで済ませていましたが、腰痛がひどくなってから思い切って投資しました。Aeron に変えてから腰痛がほぼなくなりました。長時間座るものはお金をかける価値があると実感。

      ### デスクライト
      モニターに引っかけるタイプなので場所を取らず、目が疲れにくくなりました。

      ![デスクライトの様子](https://picsum.photos/seed/desk-light/800/400)

      ## 今後追加したいもの

      - スタンディングデスク（電動昇降タイプ）
      - Webカメラのグレードアップ
      - デスクマット

      デスク環境は一度揃えると変化が少ないですが、少しずつ良くしていく過程が楽しいですね。
    MARKDOWN
    author: "admin",
    draft: false,
    created_at: 3.weeks.ago,
    updated_at: 3.weeks.ago
  },
  {
    title: "朝のルーティンを変えて生産性が上がった話",
    summary: "以前は夜型でしたが、朝型に切り替えてから仕事の質が変わりました。試行錯誤してたどり着いた朝のルーティンを紹介します。",
    thumbnail: "https://picsum.photos/seed/morning-routine/1200/630",
    body: <<~MARKDOWN,
      半年ほど前から朝型生活に切り替えました。最初の1ヶ月は辛かったですが、今では完全に習慣になっています。

      ![朝の静かな時間](https://picsum.photos/seed/morning-coffee/800/400)

      ## 現在のルーティン

      - **6:00** 起床、白湯を飲む
      - **6:15** 軽いストレッチ（15分）
      - **6:30** シャワー
      - **6:50** 朝食（シンプルに）
      - **7:15** 読書か勉強（45分）
      - **8:00** 仕事開始

      ## 変わったこと

      ### 集中力が上がった
      朝の2〜3時間は誰にも邪魔されない時間です。この時間に難しい仕事を片付けるようにしたら、午後の疲れた時間帯にしんどいタスクを残すことがなくなりました。

      ### 夜の過ごし方が変わった
      早起きするために自然と早寝するようになり、夜のだらだらスマホ時間が激減しました。

      ## 続けるコツ

      一番大事なのは**前日の夜に翌朝やることを決めておく**こと。朝に「今日何しよう」と考えると時間が無駄になります。

      夜型の人が急に朝型にするのは難しいので、最初は15分ずつ早起きを早めていくのがおすすめです。
    MARKDOWN
    author: "admin",
    draft: false,
    created_at: 1.month.ago,
    updated_at: 1.month.ago
  },
  {
    title: "Rails 8.0の新機能を試してみた",
    summary: "Rails 8.0で追加された新機能を実際に使ってみた感想とコードサンプルを紹介します。",
    thumbnail: "https://picsum.photos/seed/rails8/1200/630",
    body: <<~MARKDOWN,
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

      ![Railsの開発画面](https://picsum.photos/seed/rails-dev/800/400)

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
    author: "admin",
    draft: false,
    created_at: 2.months.ago,
    updated_at: 2.months.ago
  },
  {
    title: "読書記録: 達人プログラマー",
    summary: "ソフトウェア開発の古典的名著「達人プログラマー」を読み返しました。何年経っても色褪せない内容に改めて感動。",
    thumbnail: "https://picsum.photos/seed/book-pragmatic/1200/630",
    body: <<~MARKDOWN,
      久しぶりに「達人プログラマー」を読み返しました。最初に読んだのは5年以上前ですが、今読んでも新たな発見がありました。

      ![本棚の様子](https://picsum.photos/seed/bookshelf/800/400)

      ## 特に刺さった内容

      ### DRY原則
      「同じことを2回書くな」という原則ですが、コードだけでなく知識の重複も避けるべきという解釈が深い。ドキュメントとコードが二重管理になっているプロジェクトをよく見かけますが、これもDRY違反なんですよね。

      ### 曳光弾
      システム全体を貫く細い実装を先に作り、そこに肉付けしていくアプローチ。スケルトンを先に作るというのは今でも実践しています。

      ### 直交性
      コンポーネントが互いに影響しない設計を目指す。変更の影響範囲を小さくするということで、これはまさに今の自分の課題でもある。

      ## 読んでみて

      名著と言われる本は繰り返し読む価値がありますね。経験を積んだ後に読むと、最初は理解できなかった部分が腑に落ちたりします。

      ![読書の様子](https://picsum.photos/seed/reading/800/400)

      次は「Clean Code」を再読しようと思います。
    MARKDOWN
    author: "admin",
    draft: false,
    created_at: 10.weeks.ago,
    updated_at: 10.weeks.ago
  },
  {
    title: "おすすめのコーヒーショップ3選",
    summary: "よく仕事をしに行くコーヒーショップを紹介します。Wi-Fi完備・長居OK・電源ありの条件で選んでいます。",
    thumbnail: "https://picsum.photos/seed/coffee-shop/1200/630",
    body: <<~MARKDOWN,
      カフェで仕事をするのが好きで、いくつかお気に入りの場所があります。今回はその中からおすすめを3つ紹介。

      ![カフェの雰囲気](https://picsum.photos/seed/cafe-interior/800/400)

      ## 選ぶ基準

      - Wi-Fiが安定している
      - 電源が使える
      - 長居しても嫌な顔をされない
      - コーヒーが美味しい

      ## おすすめ3選

      ### 1. 静かな専門店系カフェ
      BGMが控えめで集中できます。スペシャルティコーヒーにこだわっていて、一杯一杯丁寧に淹れてもらえる感じが好き。

      ### 2. チェーン系（スターバックス）
      安定感があります。どこにでもあるし、電源席も確保しやすい。混んでいる時間帯を外せば快適に使えます。

      ### 3. 図書館併設のカフェ
      静かな環境で長時間作業するならここ。周りも勉強や仕事をしている人が多くて集中しやすいです。

      ![コーヒーとパソコン](https://picsum.photos/seed/coffee-laptop/800/400)

      ## 使い分け

      集中したいときは静かな専門店、サクッと作業したいときはスタバ、という感じで使い分けています。気分転換にもなりますし、場所を変えると頭が切り替わるのが良いですね。
    MARKDOWN
    author: "admin",
    draft: false,
    created_at: 3.months.ago,
    updated_at: 3.months.ago
  },
  {
    title: "GitHub Actionsで CI/CDを自動化する",
    summary: "GitHub ActionsでRailsアプリのテスト実行とデプロイを自動化した手順を解説します。設定ファイルのサンプルつき。",
    thumbnail: "https://picsum.photos/seed/github-actions/1200/630",
    body: <<~MARKDOWN,
      GitHub Actionsを使ってRailsアプリのCI/CDを構築しました。設定ファイルさえ書けば、pushするたびに自動でテストが走るようになります。

      ## 基本的なワークフロー設定

      ```yaml
      name: CI

      on:
        push:
          branches: [ main ]
        pull_request:
          branches: [ main ]

      jobs:
        test:
          runs-on: ubuntu-latest

          services:
            postgres:
              image: postgres:16
              env:
                POSTGRES_PASSWORD: postgres
              options: >-
                --health-cmd pg_isready
                --health-interval 10s
                --health-timeout 5s
                --health-retries 5

          steps:
            - uses: actions/checkout@v4
            - uses: ruby/setup-ruby@v1
              with:
                bundler-cache: true
            - name: Setup DB
              run: bundle exec rails db:create db:migrate
            - name: Run tests
              run: bundle exec rails test
      ```

      ![CI/CDパイプラインのイメージ](https://picsum.photos/seed/cicd-pipeline/800/400)

      ## キャッシュの活用

      `bundler-cache: true` を設定するだけでgemのキャッシュが効くので、2回目以降の実行が大幅に速くなります。

      ## デプロイの自動化

      mainブランチへのpushをトリガーに、Kamalでのデプロイも自動化しています。テストが通った場合のみデプロイが走るように条件を設定するのがポイントです。

      一度設定してしまえば、あとは pushするだけで全部自動で回ってくれるので本当に楽になりました。
    MARKDOWN
    author: "admin",
    draft: false,
    created_at: 4.months.ago,
    updated_at: 4.months.ago
  },
  {
    title: "Tailwind CSSでモダンなUIを作る方法",
    summary: "Tailwind CSSを使用してモダンで美しいUIを作成するためのベストプラクティスを解説します。",
    thumbnail: "https://picsum.photos/seed/tailwind/1200/630",
    body: <<~MARKDOWN,
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

      ![TailwindのUIコンポーネント例](https://picsum.photos/seed/tailwind-ui/800/400)

      ## コンポーネントの作成

      ### カードコンポーネント
      ```html
      <div class="bg-white rounded-lg shadow-md p-6">
        <h2 class="text-xl font-bold mb-4">カードタイトル</h2>
        <p class="text-gray-600">カードの内容...</p>
      </div>
      ```

      ## パフォーマンス最適化

      1. **PurgeCSS**を使用して未使用のCSSを削除
      2. **JIT mode**でビルド時間を短縮
      3. **Component extraction**で再利用性を向上

      Tailwind CSSを使うことで、効率的かつ美しいUIを構築できます。
    MARKDOWN
    author: "admin",
    draft: false,
    created_at: 5.months.ago,
    updated_at: 5.months.ago
  },
  {
    title: "週末の京都旅行",
    summary: "1泊2日で京都へ行ってきました。混雑を避けるためにあえてオフシーズンに行ったのが正解でした。",
    thumbnail: "https://picsum.photos/seed/kyoto/1200/630",
    body: <<~MARKDOWN,
      先週末、急に思い立って京都に行ってきました。今まで観光シーズンを避けていたのですが、やはりオフシーズンは快適でした。

      ![京都の街並み](https://picsum.photos/seed/kyoto-street/800/400)

      ## 1日目

      ### 午前: 伏見稲荷
      早朝に到着したおかげで、千本鳥居をほぼ独り占め状態で歩けました。朝9時を過ぎると一気に人が増えてきたので、朝イチで行くのを強くおすすめします。

      ### 午後: 祇園・八坂神社周辺
      散策しながら甘味処へ。抹茶パフェを食べてゆっくり過ごしました。

      ## 2日目

      ### 朝: 哲学の道
      春は桜、秋は紅葉が有名ですが、緑の季節も静かで良かったです。川沿いをゆっくり歩くだけで気持ちが落ち着きます。

      ![哲学の道](https://picsum.photos/seed/kyoto-path/800/400)

      ### 昼: 錦市場
      お土産を買いながら食べ歩き。漬物や湯葉など、京都らしいものをいくつか買って帰りました。

      ## まとめ

      オフシーズンの京都、最高でした。次は冬に雪景色を見に行きたいです。
    MARKDOWN
    author: "admin",
    draft: false,
    created_at: 6.months.ago,
    updated_at: 6.months.ago
  },
  {
    title: "Dockerで開発環境を構築する",
    summary: "Dockerを使ってRails + PostgreSQL + Redisの開発環境を構築する手順を解説します。チームで環境を統一するのに役立ちます。",
    thumbnail: "https://picsum.photos/seed/docker/1200/630",
    body: <<~MARKDOWN,
      「自分のPCでは動く」問題を解決するために、Dockerで開発環境を統一する方法を紹介します。

      ## docker-compose.yml の基本構成

      ```yaml
      services:
        app:
          build: .
          command: bundle exec rails server -b 0.0.0.0
          volumes:
            - .:/rails
          ports:
            - "3000:3000"
          depends_on:
            - db
            - redis
          environment:
            DATABASE_URL: postgres://postgres:password@db:5432/myapp_development

        db:
          image: postgres:16
          environment:
            POSTGRES_PASSWORD: password
          volumes:
            - postgres_data:/var/lib/postgresql/data

        redis:
          image: redis:7-alpine

      volumes:
        postgres_data:
      ```

      ![Dockerの構成図](https://picsum.photos/seed/docker-diagram/800/400)

      ## Dockerfile

      ```dockerfile
      FROM ruby:3.4
      WORKDIR /rails
      COPY Gemfile Gemfile.lock ./
      RUN bundle install
      COPY . .
      EXPOSE 3000
      ```

      ## よくあるハマりポイント

      - ファイルの変更が反映されない → volumeのマウント設定を確認
      - bundle installが遅い → gemのキャッシュをvolumeに設定する
      - DBに接続できない → `depends_on` だけでは不十分、ヘルスチェックも設定する

      一度設定してしまえば `docker compose up` 一発で環境が立ち上がるので、チーム開発には必須のツールだと思います。
    MARKDOWN
    author: "admin",
    draft: false,
    created_at: 7.months.ago,
    updated_at: 7.months.ago
  },
  {
    title: "開発効率を上げるVSCodeの設定",
    summary: "VSCodeの設定をカスタマイズして開発効率を大幅に向上させる方法を紹介します。",
    thumbnail: "https://picsum.photos/seed/vscode/1200/630",
    body: <<~MARKDOWN,
      VSCodeの設定をカスタマイズして、開発効率を向上させましょう。

      ## 必須拡張機能

      ### 1. プログラミング言語
      - **Ruby LSP** - Ruby言語サポート
      - **JavaScript (ES6) code snippets** - JSスニペット
      - **Tailwind CSS IntelliSense** - Tailwindの補完

      ### 2. 開発支援
      - **GitLens** - Git履歴の可視化
      - **Prettier** - コードフォーマッター
      - **ESLint** - JavaScriptリンター

      ![VSCodeの拡張機能画面](https://picsum.photos/seed/vscode-extensions/800/400)

      ## settings.jsonの設定

      ```json
      {
        "editor.fontSize": 14,
        "editor.tabSize": 2,
        "editor.formatOnSave": true,
        "files.autoSave": "afterDelay",
        "editor.minimap.enabled": false,
        "editor.wordWrap": "on"
      }
      ```

      ## キーボードショートカット

      - `Cmd + Shift + P` - コマンドパレット
      - `Cmd + P` - ファイル検索
      - `Cmd + D` - 複数選択
      - `Alt + ↑/↓` - 行の移動

      これらの設定により、開発効率が大幅に向上します！
    MARKDOWN
    author: "admin",
    draft: false,
    created_at: 8.months.ago,
    updated_at: 8.months.ago
  },
  {
    title: "JavaScript最新機能まとめ",
    summary: "ES2023で追加された最新のJavaScript機能を実例とともに紹介します。",
    thumbnail: "https://picsum.photos/seed/javascript/1200/630",
    body: <<~MARKDOWN,
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
      ```

      ![JavaScriptのコード例](https://picsum.photos/seed/js-code/800/400)

      ### 3. Array.prototype.toSorted()
      ```javascript
      const arr = [3, 1, 2];
      const sorted = arr.toSorted();
      console.log(sorted); // [1, 2, 3]
      console.log(arr); // [3, 1, 2] (元の配列は変更されない)
      ```

      これらの新機能により、イミュータブルなデータ操作がより簡単になりました。
    MARKDOWN
    author: "admin",
    draft: false,
    created_at: 9.months.ago,
    updated_at: 9.months.ago
  },
  {
    title: "Ruby on Railsのベストプラクティス",
    summary: "長年のRails開発経験から得られたベストプラクティスとアンチパターンを紹介します。",
    thumbnail: "https://picsum.photos/seed/ruby-rails/1200/630",
    body: <<~MARKDOWN,
      Railsアプリケーションの品質を向上させるためのベストプラクティスをまとめました。

      ## コードの構造化

      ### Fat ModelよりもService Object
      ```ruby
      # Good
      class UserRegistrationService
        def initialize(user)
          @user = user
        end

        def call
          send_welcome_email
          create_profile
        end
      end
      ```

      ![Railsのアーキテクチャ図](https://picsum.photos/seed/rails-architecture/800/400)

      ### 適切なバリデーション
      ```ruby
      class Article < ApplicationRecord
        validates :title, presence: true, length: { maximum: 255 }
        validates :body, presence: true
      end
      ```

      ## N+1問題の回避
      ```ruby
      # Good
      articles = Article.includes(:comments)
      articles.each { |article| puts article.comments.count }
      ```

      これらのベストプラクティスを実践することで、保守性の高いRailsアプリケーションを構築できます。
    MARKDOWN
    author: "admin",
    draft: false,
    created_at: 10.months.ago,
    updated_at: 10.months.ago
  },

  # ===== 下書き記事 (15件) =====
  {
    title: "PostgreSQLのパフォーマンスチューニング",
    summary: "本番環境で遅いクエリに悩んでいる人向けに、PostgreSQLのパフォーマンスチューニングの手順と実例をまとめました。",
    thumbnail: "https://picsum.photos/seed/postgresql/1200/630",
    body: <<~MARKDOWN,
      本番環境でスロークエリが発生したときの調査・改善の流れをまとめます。

      ## EXPLAIN ANALYZEで確認する

      ```sql
      EXPLAIN ANALYZE
      SELECT * FROM articles
      WHERE author = 'admin'
      ORDER BY created_at DESC
      LIMIT 20;
      ```

      ![クエリ実行計画のイメージ](https://picsum.photos/seed/database/800/400)

      ## インデックスの追加

      ```ruby
      class AddIndexToArticles < ActiveRecord::Migration[8.0]
        def change
          add_index :articles, [:author, :draft, :created_at]
        end
      end
      ```

      ## N+1クエリの検出

      `bullet` gemを使うと開発中にN+1クエリを検出できます。

      ```ruby
      # Gemfile
      gem 'bullet', group: :development
      ```

      ## まとめ

      パフォーマンス改善は計測から始めることが大事。なんとなくインデックスを追加するのではなく、実際に遅いクエリを特定してから対処しましょう。
    MARKDOWN
    author: "admin",
    draft: true,
    created_at: 3.days.ago,
    updated_at: 3.days.ago
  },
  {
    title: "来週のリリース予定について",
    summary: "来週リリース予定の新機能と改善点について詳しく説明します。",
    thumbnail: "https://picsum.photos/seed/release/1200/630",
    body: <<~MARKDOWN,
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

      ![新機能のスクリーンショット](https://picsum.photos/seed/new-feature/800/400)

      ## 改善点

      - データベースクエリの最適化
      - レスポンシブデザインの対応
      - アクセシビリティの向上

      ※この記事は下書きです。リリース前に内容を確認してください。
    MARKDOWN
    author: "admin",
    draft: true,
    created_at: 1.day.ago,
    updated_at: 1.day.ago
  },
  {
    title: "夏の沖縄旅行計画",
    summary: "今年の夏は沖縄に行く予定です。行きたい場所や食べたいものをリストアップしました。",
    thumbnail: "https://picsum.photos/seed/okinawa/1200/630",
    body: <<~MARKDOWN,
      今年の夏休みは沖縄に行くことにしました。まだ計画段階ですが、行きたい場所をまとめておきます。

      ![沖縄の海](https://picsum.photos/seed/okinawa-sea/800/400)

      ## 行きたい場所

      - 美ら海水族館（ジンベエザメを見たい！）
      - 古宇利島
      - 首里城（まだ行ったことがない）
      - 国際通り

      ## 食べたいもの

      - ソーキそば
      - タコライス
      - ブルーシールアイス
      - 海ぶどう

      ## 移動手段

      沖縄はレンタカーが必須らしいので、早めに予約しないといけない。バスだと不便な場所が多いとのこと。

      ![リゾートの景色](https://picsum.photos/seed/resort/800/400)

      まだ計画段階なので、おすすめスポットがあれば教えてください！
    MARKDOWN
    author: "admin",
    draft: true,
    created_at: 1.week.ago,
    updated_at: 1.week.ago
  },
  {
    title: "新しいキーボードを買った",
    summary: "HHKBを購入しました。打鍵感がこれまでと全然違って、タイピングが楽しくなりました。",
    thumbnail: "https://picsum.photos/seed/keyboard/1200/630",
    body: <<~MARKDOWN,
      ずっと気になっていたHHKB（Happy Hacking Keyboard）を購入しました。

      ![HHKBの写真](https://picsum.photos/seed/hhkb-keyboard/800/400)

      ## 選んだ理由

      - 打鍵感が良いと評判だった
      - コンパクトで持ち運べる
      - 長く使えそう（壊れにくい）

      ## 使ってみた感想

      ### 良かった点
      打鍵感が全然違います。メンブレンキーボードに比べて、タイピングがとにかく気持ちいい。カフェで作業していると周りに音が気になるかも？という懸念がありましたが、思ったより静かでした。

      ### 慣れが必要な点
      Deleteキーの位置が独特で最初は戸惑いました。あとファンクションキーがないので、Fnキーとの組み合わせで操作することになります。

      ## 1週間使ってみて

      すでに元のキーボードには戻れなくなっています。手が疲れにくくなった気がするし、なによりタイピングが楽しい。

      買って良かったです。
    MARKDOWN
    author: "admin",
    draft: true,
    created_at: 2.weeks.ago,
    updated_at: 2.weeks.ago
  },
  {
    title: "Next.jsとRailsのAPI連携",
    summary: "フロントエンドにNext.js、バックエンドにRails APIを使った構成を試してみました。認証周りとCORSの設定がポイントです。",
    thumbnail: "https://picsum.photos/seed/nextjs-rails/1200/630",
    body: <<~MARKDOWN,
      Next.js + Rails API の構成を試してみたメモです。

      ## Rails側の設定

      ```ruby
      # config/application.rb
      config.api_only = true
      ```

      ```ruby
      # Gemfile
      gem 'rack-cors'
      ```

      ```ruby
      # config/initializers/cors.rb
      Rails.application.config.middleware.insert_before 0, Rack::Cors do
        allow do
          origins 'http://localhost:3001'
          resource '*', headers: :any, methods: [:get, :post, :put, :patch, :delete]
        end
      end
      ```

      ![Next.jsとRailsの連携図](https://picsum.photos/seed/api-diagram/800/400)

      ## Next.js側からAPIを呼ぶ

      ```typescript
      const response = await fetch('http://localhost:3000/api/articles', {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        }
      });
      const articles = await response.json();
      ```

      ## 認証

      JWTを使ったトークン認証を実装しました。`devise-jwt` gemが便利です。

      まだ調整中の部分もあるので、完成したら改めて詳しく書きます。
    MARKDOWN
    author: "admin",
    draft: true,
    created_at: 3.weeks.ago,
    updated_at: 3.weeks.ago
  },
  {
    title: "自炊を始めて気づいたこと",
    summary: "テイクアウト生活からほぼ毎日自炊するようになりました。食費が下がっただけでなく、意外な副次効果もありました。",
    thumbnail: "https://picsum.photos/seed/cooking/1200/630",
    body: <<~MARKDOWN,
      去年まではほぼ毎日テイクアウトかコンビニ飯でしたが、今年から自炊を増やしました。

      ![料理の様子](https://picsum.photos/seed/home-cooking/800/400)

      ## きっかけ

      食費がかさんでいたのと、体の調子が悪かったのが重なって「食生活を変えよう」と思い立ちました。

      ## 変わったこと

      ### 食費が下がった
      月の食費が約3割減りました。外食やテイクアウトはやはり割高だと実感。

      ### 調理が意外と楽しい
      最初は面倒だと思っていたのですが、料理に集中している時間が頭のリセットになっています。

      ### 野菜の摂取量が増えた
      自炊だと野菜を入れやすい。コンビニ弁当だとどうしても偏りがちでした。

      ## よく作るもの

      - 野菜炒め（最速・最強）
      - 味噌汁（具材を変えれば飽きない）
      - 卵料理（万能）

      ![作った料理の一例](https://picsum.photos/seed/food/800/400)

      ## まとめ

      「自炊は大変」というイメージがありましたが、シンプルな料理から始めれば全然大変じゃないです。続けるコツは完璧を求めないこと。
    MARKDOWN
    author: "admin",
    draft: true,
    created_at: 1.month.ago,
    updated_at: 1.month.ago
  },
  {
    title: "最近ハマっているポッドキャスト",
    summary: "散歩や家事の時間に聴いているポッドキャストを紹介します。技術系からライフスタイル系まで幅広く。",
    thumbnail: "https://picsum.photos/seed/podcast/1200/630",
    body: <<~MARKDOWN,
      最近はYouTubeよりポッドキャストを聴く時間が増えました。ながら聴きできるのが良い。

      ## 技術系

      ### Rebuild.fm
      日本語の技術系ポッドキャストの定番。エンジニアのキャリアや技術トレンドの話が多く、聴いていて刺激になります。

      ### fukabori.fm
      インフラやSRE周りの深い話が多い。自分の専門外の話を聞くのが好きで、毎回新しい発見があります。

      ## ライフスタイル系

      ### 超リアルなやつ（仮称）
      友人がやっているポッドキャスト。日常の話がゆるくてリラックスできます。

      ![ポッドキャストを聴く様子](https://picsum.photos/seed/listening/800/400)

      ## 聴くタイミング

      - 朝の散歩中
      - 料理しながら
      - 皿洗いしながら

      まとめてドキュメントを読むより、ながら聴きで継続的にインプットする方が自分には合っている気がします。おすすめのポッドキャストがあれば教えてください。
    MARKDOWN
    author: "admin",
    draft: true,
    created_at: 6.weeks.ago,
    updated_at: 6.weeks.ago
  },
  {
    title: "Redisを使ったキャッシュ戦略",
    summary: "RailsアプリにRedisを導入してキャッシュを実装しました。どこに何をキャッシュするかの判断基準も含めて解説します。",
    thumbnail: "https://picsum.photos/seed/redis/1200/630",
    body: <<~MARKDOWN,
      Railsアプリのパフォーマンス改善でRedisキャッシュを導入した際のメモです。

      ## 設定

      ```ruby
      # config/environments/production.rb
      config.cache_store = :redis_cache_store, {
        url: ENV["REDIS_URL"],
        expires_in: 1.hour
      }
      ```

      ## キャッシュの基本

      ```ruby
      # fragment cache
      Rails.cache.fetch("articles/top", expires_in: 30.minutes) do
        Article.published.order(created_at: :desc).limit(10)
      end
      ```

      ![キャッシュの仕組み図](https://picsum.photos/seed/cache-diagram/800/400)

      ## どこをキャッシュするか

      キャッシュすべき候補:
      - 頻繁に参照されるが変更頻度が低いデータ
      - 計算コストが高い処理の結果
      - 外部APIのレスポンス

      キャッシュしないほうが良いもの:
      - ユーザーごとに異なるデータ（注意が必要）
      - 変更頻度が高いデータ

      ## キャッシュの無効化

      ```ruby
      # 記事更新時にキャッシュをクリア
      after_save :clear_cache

      def clear_cache
        Rails.cache.delete("articles/top")
      end
      ```

      キャッシュの導入はパフォーマンス改善に効果的ですが、キャッシュの無効化を正しく実装しないと古いデータが表示され続けます。注意して設計しましょう。
    MARKDOWN
    author: "admin",
    draft: true,
    created_at: 2.months.ago,
    updated_at: 2.months.ago
  },
  {
    title: "ホームオフィスのインテリア改善",
    summary: "リモートワークが続くので、部屋の中でも仕事モードに入りやすい環境づくりを試みました。",
    thumbnail: "https://picsum.photos/seed/home-office/1200/630",
    body: <<~MARKDOWN,
      在宅勤務が増えてから、作業スペースの快適さに投資するようになりました。

      ![改善後のホームオフィス](https://picsum.photos/seed/office-interior/800/400)

      ## 変えたこと

      ### 観葉植物を置いた
      モニターの横にパキラを置きました。緑があるだけで部屋の雰囲気が柔らかくなります。水やりの手間もそれほどなくて良い。

      ### 照明を変えた
      蛍光灯からLED電球（昼白色）に変えました。色温度で集中力が変わるという話は本当で、作業中は明るめの白色が向いているようです。

      ### ケーブルの整理
      デスク周りがケーブルでごちゃごちゃしていたのをケーブルトレーとマジックテープで整理。見た目がすっきりしただけで気持ちが違います。

      ## 費用

      - 観葉植物: 2,000円
      - LED電球（2個）: 1,500円
      - ケーブル整理グッズ: 1,000円

      合計4,500円程度でかなり快適になりました。

      ![植物とデスクの様子](https://picsum.photos/seed/plant-desk/800/400)

      大規模な改装をしなくても、小さな改善の積み重ねで作業環境は大きく変わりますね。
    MARKDOWN
    author: "admin",
    draft: true,
    created_at: 10.weeks.ago,
    updated_at: 10.weeks.ago
  },
  {
    title: "テスト駆動開発のすすめ",
    summary: "TDDを実践するようになってから、コードの設計が改善されました。最初の一歩をどう踏み出すか、具体的な手順を紹介します。",
    thumbnail: "https://picsum.photos/seed/tdd/1200/630",
    body: <<~MARKDOWN,
      テスト駆動開発（TDD）を実践するようになって半年が経ちました。最初は面倒に感じていましたが、今は手放せなくなっています。

      ## TDDの基本サイクル

      1. **Red**: 失敗するテストを書く
      2. **Green**: テストが通る最小限のコードを書く
      3. **Refactor**: コードをきれいにする

      ## 実際のRailsでの例

      ```ruby
      # まずテストを書く
      test "記事タイトルは必須" do
        article = Article.new(body: "本文")
        assert_not article.valid?
        assert_includes article.errors[:title], "can't be blank"
      end

      # テストが通るコードを書く
      class Article < ApplicationRecord
        validates :title, presence: true
      end
      ```

      ![TDDのサイクル図](https://picsum.photos/seed/tdd-cycle/800/400)

      ## TDDのメリット

      - テストを書くことで要件が明確になる
      - 設計が自然とシンプルになる
      - リファクタリングへの恐怖がなくなる

      ## よくある誤解

      「TDDは時間がかかる」という意見をよく聞きますが、長期的には逆です。バグ修正やリグレッション防止の時間が減るので、トータルでは効率的です。

      まずは小さい機能から試してみてください。
    MARKDOWN
    author: "admin",
    draft: true,
    created_at: 3.months.ago,
    updated_at: 3.months.ago
  },
  {
    title: "秋の登山レポート",
    summary: "紅葉シーズンに日帰りで登山してきました。初心者でも登れる山を選びましたが、それでもいい運動になりました。",
    thumbnail: "https://picsum.photos/seed/autumn-mountain/1200/630",
    body: <<~MARKDOWN,
      紅葉が見頃という情報を見て、登山初心者でも登れる山に挑戦してきました。

      ![秋の山の風景](https://picsum.photos/seed/mountain-autumn/800/400)

      ## 行った山

      標高1000m程度の低山。登山口から山頂まで約2時間、下山1.5時間のコースです。

      ## 当日の様子

      朝7時に出発。紅葉のピークは少し過ぎていましたが、それでも赤や黄色に染まった木々がきれいでした。

      途中、何組かの登山者とすれ違いながらゆっくり歩いて山頂へ。山頂からの眺めが最高で、持参したお弁当が格別に美味しかったです。

      ## 持ち物

      - 登山靴（大事！スニーカーは滑る）
      - レインウェア
      - 水1.5L
      - 行動食（チョコや飴）
      - 地図とコンパス

      ![山頂からの眺め](https://picsum.photos/seed/mountain-view/800/400)

      ## まとめ

      日帰り低山は体力的にもちょうど良く、自然の中を歩くのはリフレッシュになります。春先にも行きたいと思っています。
    MARKDOWN
    author: "admin",
    draft: true,
    created_at: 4.months.ago,
    updated_at: 4.months.ago
  },
  {
    title: "読書記録: Clean Architecture",
    summary: "Robert C. Martinの「Clean Architecture」を読みました。アーキテクチャの考え方が根本から変わった一冊です。",
    thumbnail: "https://picsum.photos/seed/book-clean/1200/630",
    body: <<~MARKDOWN,
      「Clean Architecture」を読んで、アーキテクチャに対する考え方が変わりました。

      ## 核心: 依存関係の方向

      この本で一番大事なのは「依存関係の方向をコントロールする」という考え方です。ビジネスロジックはフレームワークやDBに依存してはいけない。

      ```
      UI → Application → Domain ← Infrastructure
      ```

      ドメイン層は何にも依存しない。これが Clean Architecture の核心。

      ![アーキテクチャの図](https://picsum.photos/seed/clean-arch/800/400)

      ## Railsでどう実践するか

      Railsは「フレームワークに乗っかる」設計なので、Clean Architecture とは相性が良くないとも言われます。でも大事なのは思想を理解すること。

      - Fat Controller を避ける
      - ビジネスロジックは Service Object や Domain Object に
      - Active Record はデータアクセス層として割り切る

      ## 読んでみた感想

      全部を厳密に実践するのは難しいですが、「変更に強いコードを書く」という意識は持てるようになりました。

      技術書の中でも読んで良かったと感じる一冊です。チームで読んで議論するのも良さそう。
    MARKDOWN
    author: "admin",
    draft: true,
    created_at: 5.months.ago,
    updated_at: 5.months.ago
  },
  {
    title: "GraphQL入門",
    summary: "REST APIとGraphQLの違いと、RailsでGraphQLを使い始める手順を解説します。",
    thumbnail: "https://picsum.photos/seed/graphql/1200/630",
    body: <<~MARKDOWN,
      GraphQLについて調べたことをまとめます。

      ## REST APIとの違い

      | | REST | GraphQL |
      |---|---|---|
      | エンドポイント | 複数 | 単一 |
      | データ取得 | サーバー定義 | クライアント定義 |
      | オーバーフェッチ | 起きやすい | 起きにくい |

      ## Railsでの設定

      ```ruby
      # Gemfile
      gem 'graphql'

      # スキーマの定義
      class Types::ArticleType < Types::BaseObject
        field :id, ID, null: false
        field :title, String, null: false
        field :body, String, null: false
        field :created_at, GraphQL::Types::ISO8601DateTime, null: false
      end
      ```

      ![GraphQLのクエリ例](https://picsum.photos/seed/graphql-query/800/400)

      ## クエリの例

      ```graphql
      query {
        articles {
          id
          title
          createdAt
        }
      }
      ```

      必要なフィールドだけ取得できるので、モバイルアプリとの連携に特に向いています。

      まだ勉強中なので、実際のプロジェクトで使ってみてから改めて記事にします。
    MARKDOWN
    author: "admin",
    draft: true,
    created_at: 6.months.ago,
    updated_at: 6.months.ago
  },
  {
    title: "マイクロサービスアーキテクチャの設計",
    summary: "モノリシックなRailsアプリをマイクロサービスに分割する際の考え方と、やってみて感じた難しさを正直に書きます。",
    thumbnail: "https://picsum.photos/seed/microservices/1200/630",
    body: <<~MARKDOWN,
      モノリスをマイクロサービスに分割するプロジェクトに関わった経験をまとめます。

      ## そもそもなぜマイクロサービスか

      - スケーラビリティの向上
      - デプロイの独立性
      - チームの自律性

      ただし、これらのメリットが必要かどうかを先に問うべきです。小規模なチームや初期フェーズではモノリスの方が良いことが多い。

      ![マイクロサービスの構成図](https://picsum.photos/seed/microservice-diagram/800/400)

      ## 難しかった点

      ### サービス間通信
      HTTPかgRPCか、同期か非同期か、の選択が難しい。

      ### 分散トランザクション
      DBが分かれると、複数サービスにまたがるトランザクションが難しくなります。

      ### 運用コスト
      サービスの数だけモニタリングやログ収集の仕組みが必要になる。

      ## 感想

      「マイクロサービス = モダン」という誤解がありますが、適切な規模感とチーム体制がないと負債になります。まずモノリスをきれいに保つことを優先すべきでした。
    MARKDOWN
    author: "admin",
    draft: true,
    created_at: 8.months.ago,
    updated_at: 8.months.ago
  },
  {
    title: "Rustの所有権システムを理解する",
    summary: "RustのRustたる所以、所有権システムを学びました。最初は難解でしたが、理解するとメモリ安全の考え方が根本から変わります。",
    thumbnail: "https://picsum.photos/seed/rust-lang/1200/630",
    body: <<~MARKDOWN,
      Rustの勉強を始めて、所有権システムという独特の概念でつまずきました。そこで学んだことをまとめます。

      ## 所有権の3つのルール

      1. 各値は「所有者」と呼ばれる変数を持つ
      2. 一度に所有者は一人だけ
      3. 所有者がスコープから外れると値は破棄される

      ```rust
      fn main() {
          let s1 = String::from("hello");
          let s2 = s1; // s1の所有権がs2に移動

          // println!("{}", s1); // エラー！s1はもう使えない
          println!("{}", s2); // OK
      }
      ```

      ![Rustのコード例](https://picsum.photos/seed/rust-code/800/400)

      ## 借用（Borrowing）

      ```rust
      fn calculate_length(s: &String) -> usize {
          s.len()
      } // sはここでスコープを外れるが、参照なので値は破棄されない

      fn main() {
          let s1 = String::from("hello");
          let len = calculate_length(&s1);
          println!("'{}' の長さは {} です", s1, len);
      }
      ```

      ## 理解してわかったこと

      所有権システムはコンパイル時にメモリ安全を保証するための仕組みです。GCなしでメモリリークやダングリングポインタを防げる。

      最初はコンパイラに怒られてばかりですが、慣れると「この設計おかしくない?」というのをコンパイラが教えてくれる感じで頼もしくなります。
    MARKDOWN
    author: "admin",
    draft: true,
    created_at: 10.months.ago,
    updated_at: 10.months.ago
  }
]

sample_articles.each do |article_data|
  Article.find_or_initialize_by(title: article_data[:title]).tap do |article|
    article.assign_attributes(article_data.except(:title))
    article.save!
  end
end

puts "初期データの作成が完了しました！"
puts "Admin: admin@example.com / admin123"
puts "Articles: #{Article.count}件の記事が作成されました"
puts "Published: #{Article.published.count}件"
puts "Drafts: #{Article.drafts.count}件"
