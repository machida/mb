# 2026-10-31 公開画面の背景修正

- パンくず背景を `#d6dde6` から `#eae7df` へ変更。
- 本番のメインビジュアルは画像URLが200でも、nonce付きCSPによりinline style属性が無効になり、computed background-imageがnoneになっていた。
- 固定画像の指定を外部CSSへ移し、Propshaftによるdigest URL解決を使用する。CSP自体は変更しない。
- コントローラーテストでinline style属性がないこと、E2EでCSP適用下の背景画像URLと画像の200応答を検証する。
- 全体テストでローカルRailsサーバーの30秒起動タイムアウトが1回発生。待機上限をCIと同じ60秒へ揃え、`log/playwright-server-<port>.log` に起動ログを残して再検証する。

検証: `bundle exec rails test:all --seed 44182` は375 runs / 1350 assertions / 0 failures / 0 errors / 0 skips。Tailwindビルド・npm lint・RuboCop・diff checkも成功。
