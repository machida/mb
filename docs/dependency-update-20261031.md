# 2026-10-31 依存更新

## PR統合

PR #200〜#211のうちオープンだった11件をマージ（#205は対象外）。main `18b4359` で376 runs / 1281 assertions / 0 failures / 0 errors / 13 skips。CIの旧Rubyと新Ubuntuの組み合わせによる起動失敗を解消した。

## 更新内容

- Ruby 4.0.9、Bundler 4.0.23、Rails 8.1.4、Node.js 26.13.0 LTS。
- Gemfile.lockを全更新。PlaywrightはRubyクライアント1.64.0とnpm 1.64.1（同じ1.64系）を使用。
- CIはRubyを `.ruby-version`、Nodeを `.node-version` から読み、Dockerも同じRubyとNode 26系を使用。
- npmは `npm ci` でロックファイルを再現する。ESLint依存のminimatchはGHSA-g3hv-75wg-m249対応の11.0.3以降へoverrideし、lintを実行して互換性を確認する。
- Cropper.jsは既存API互換の最新版1.7.0。npmのCSSとvendored ESMを揃えた。2.3.1はWeb ComponentsベースのAPI移行が必要なため今回の更新対象外。
- GCSのテストで必要なgemを明示的に読み込み、スキップされていたケースを実行する。空のGCSテストは委譲・エラー伝播の検証へ置き換えた。AI概要生成はブラウザ側のHTTPモックを使って成功ケースを検証する。

## 上流制約による据え置き

`bundle outdated` で残る4件は直接依存gemの制約によるもの。

- marcel 1.2.1: Active Storageが `~> 1.0` を要求。
- net-ssh 7.3.8: Kamalが `~> 7.3` を要求。
- prism 1.9.0: MiniTestとrubocop-astが1系を要求。
- retriable 4.2.0: google-apis-coreが `< 5.0` を要求。

## 検証

- `COVERAGE=true bundle exec rails test:all`: 375 runs / 1344 assertions / 0 failures / 0 errors / 0 skips。行カバレッジ91.88%、分岐84.69%。
- `npm run lint`: エラー0。既存のJavaScript警告3件とparserのRuby対応警告あり。SimpleCovにも旧APIの非推奨警告あり。
- `bundle exec rubocop`: 47ファイル、違反0。
- `npm audit`: 脆弱性0。
- GCS・画像アップロード関連: 21 runs / 85 assertions / 0 failures / 0 errors / 0 skips。

ローカルの未追跡 `Materials/` は変更・コミット対象外。
