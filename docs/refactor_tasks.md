# Refactor Backlog

コードベースで気になったリファクタ候補と、着手時に役立つメモをまとめています。優先度は概ね上から順です。

## 1. アーカイブ系クエリをDB非依存にする
- **場所**: `app/controllers/articles_controller.rb:17-37`
- **課題**: `strftime` を使ったwhere/groupはSQLite専用構文。`CLAUDE.md`の環境情報では本番はPostgreSQLのため、アーカイブ画面が動かなくなるリスクがある。
- **方針**:
  - 年/月の範囲をRubyで計算 (`Time.zone.local(year, 1, 1)` など) し、`where(created_at: range)` を使う。
  - 月別カウントは `group_by_month` 相当の範囲クエリに置き換えるか、ARで `DATE_TRUNC` を使うヘルパーを用意する。
  - 変更後はSQLite/PG両方でsystemテストを通す。

## 2. 記事の公開/下書き状態遷移を集約
- **場所**: `app/controllers/admin/articles_controller.rb:17-54`
- **課題**: `params[:commit]` の文言に依存した分岐が create/update 両方に重複。ドラフト判定やリダイレクト文面も重複しており、ボタン文言変更時に漏れやすい。
- **方針**:
  - `ArticlePublicationCommand` のような小さなサービス/フォームオブジェクトに「次の状態」を判定させる。
  - 成功時の遷移/メッセージ生成も同オブジェクトで行い、コントローラは `result.redirect_target` を使うだけにする。
  - 既存のcontrollerテスト/Playwrightテストへケース追加。

## 3. 画像アップロードサービスの責務分離
- **場所**: `app/services/image_upload_service.rb:2-190`
- **課題**: 単一クラスが (1) 入力検証 (2) 画像処理 (3) ストレージ(GCS/ローカル) の3責務を抱え190行。環境分岐やImageProcessing設定の重複も多くテストしづらい。
- **方針**:
  - `UploadTarget`（GCS/Local）と `ImageProfile`（content/thumbnail）を小さなクラスで切り出し、共通の処理パイプラインを組む。
  - 画像処理設定を定数化し、サムネ/本文で数値が散在しないようにする。
  - 単体テストで各プロファイルのリサイズ結果とcontent_typeを検証できるようにする。

## 4. Markdown描画のインスタンス化コスト削減
- **場所**: `app/helpers/application_helper.rb:16-40`
- **課題**: `markdown` ヘルパー呼び出し毎に `Redcarpet::Markdown` と `Rouge` formatter を再生成しておりView内での複数呼び出し時に無駄が大きい。`ArticlesController` でも `helpers.markdown` を返すAPIがあり、パフォーマンス影響が出やすい。
- **方針**:
  - ヘルパーで `@markdown_renderer ||= ...` のようにメモ化するか、`MarkdownRenderer` サービスを導入。
  - スレッドセーフにするため、オブジェクトが状態を持たないか確認しつつ、必要なら `Concurrent::Map` でcaches。

## 5. 著者表示判定ロジックの一元化
- **場所**: `app/controllers/articles_controller.rb:4-37`, `app/helpers/application_helper.rb:48-50`
- **課題**: 著者表示可否ロジックがHelper/Controllerで重複。SQLも `Article.published.select(:author).distinct.count` を毎回叩いており無駄。
- **方針**:
  - `Articles::AuthorDisplayPolicy` などに抽出し、`SiteSetting.author_display_enabled? && author_count >= 2` を1箇所に定義。
  - カウント結果はキャッシュ化（例: `Rails.cache.fetch("published_author_count")`）して、InvalidateをPublish時にかける。

## 6. ドロップダウン挙動をStimulus化
- **場所**: `app/javascript/dropdown.js:2-62`
- **課題**: Turbo遷移ごとに `document.addEventListener` が増殖し、メモリリークや多重close処理が発生しうる。`data-dropdown-initialized` はボタン単位でしか判定していない。
- **方針**:
  - 既にStimulusが使えるので `DropdownController` を作成し、connect/disconnectでリスナーを管理。
  - document全体に張るリスナーは `AbortController` か `userEvent = this.handleDocumentClick` でremoveする。
  - Playwrightテストで複数Turbo遷移後も単発で閉じることを確認。

## 7. サイト設定更新ロジックのフォーム化
- **場所**: `app/controllers/admin/site_settings_controller.rb:2-80`
- **課題**: Strong Parametersで受けたHashをそのままループしており、バリデーションもない。キー名を文字列で比較していてミスしやすい。またcontrollerにビジネスロジックが散在。
- **方針**:
  - `SiteSettingsForm` を作り、属性ごとの型/allow_blank/変換処理（著作権者抽出）をそこで行う。
  - `form.save` でまとめて `SiteSetting.set` を呼び、失敗時にエラー詳細を返せるようにする。
  - 既存PlaywrightテストにOG画像削除ケースなどを追加。

## 8. パスワードリセット更新処理のバリデーション共通化
- **場所**: `app/controllers/admin/password_resets_controller.rb:25-52`
- **課題**: Controllerでパスワードのblank/一致/長さチェックを都度実装しており、`Admin` モデルのバリデーションと二重管理。文言の重複やロジック漏れの温床。
- **方針**:
  - `PasswordResetForm`（ActiveModel::Model）を作成し、`validates :password, presence: true, confirmation: true, length: { minimum: 8 }` を集約。
  - Controllerは `form.submit` の結果で分岐し、エラーは `form.errors.full_messages` を使って表示。
  - 既存mailer/featureテストにフォームオブジェクト経由のケースを追加。

