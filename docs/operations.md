# 運用 Runbook（本番）

本番は Kamal で 1台の VPS にデプロイしています。本書は障害対応・再発防止のための手順をまとめたものです。

## CIのCoverallsダウンロード障害

Coverallsのレポーター・チェックサム取得が504になる場合、HTMLエラーページがチェックサム不一致の原因になることがあります。レポーターのバージョン固定だけでは解消しません。CIではCoverallsステップに限り `CURL_HOME` で `.github/coveralls-curl/.curlrc` を読み込み、HTTPエラー検知と最大3回の再試行を行います。各取得は60秒、再試行開始の時間枠は180秒に制限しています（開始済みの取得は枠を超えて続く場合があります）。

再試行後も失敗したら、GitHub Releasesの配布状態を確認してから失敗ジョブを再実行してください。チェックサム検証や `fail-on-error` を無効化して通過させないでください。`test/lib/coveralls_download_test.rb` で一時的・継続的な504への動作を検証します。

## 構成サマリ
- 次回ビルドのランタイム: Ruby 4.0.9 / Rails 8.1.4.1、アセット構築はNode.js 26系。実際の本番反映はGitHub Actionsのdeploy完了と `/up` で確認する。
- ホスト: さくらVPS `153.121.42.228`（ドメイン `mxchida.com`）／ RAM 約1GB
- 接続: SSH `ubuntu` ユーザ（root直ログイン不可）。鍵はローカルの `~/.ssh/id_rsa`
  ```bash
  ssh -i ~/.ssh/id_rsa ubuntu@153.121.42.228
  ```
- 構成: `kamal-proxy`（SSL終端・80/443）→ アプリコンテナ `mb-web-<sha>`（Thruster:80 → Puma:3000）
- ジョブ: `SOLID_QUEUE_IN_PUMA=true` のため SolidQueue は web と同じコンテナで稼働
- ヘルスチェック: `/up`（Kamal proxy が10秒間隔、Docker HEALTHCHECK も併用）

## 502 が出たときの復旧手順
502 は「kamal-proxy は生きているがアプリコンテナがダウン」を意味します。

```bash
ssh -i ~/.ssh/id_rsa ubuntu@153.121.42.228

# 1. 状態確認（OOMKilled / ExitCode を見る）
docker ps -a --format '{{.Names}}\t{{.Status}}' | grep -E 'mb-web|proxy'
docker inspect <mb-web-コンテナ名> \
  --format 'OOMKilled={{.State.OOMKilled}} ExitCode={{.State.ExitCode}} FinishedAt={{.State.FinishedAt}}'

# 2. 不要な孤児/古いコンテナを掃除（メモリ解放）
docker ps -a --format '{{.Names}}\t{{.Status}}' | grep mb-web   # 確認してから
docker rm <停止中の不要コンテナ>

# 3. 現行コンテナを起動（最新のものが docker ps -a の先頭）
docker start <mb-web-コンテナ名>

# 4. 検証（内部 → 外部の順で200を確認）
docker exec <mb-web-コンテナ名> curl -s -o /dev/null -w '%{http_code}\n' http://localhost/up
curl -s -o /dev/null -w '%{http_code}\n' https://mxchida.com/up
```

正規にやり直す場合はローカルから `bin/kamal deploy`。

## 再発防止チェックリスト

### 1. スワップ（最優先・OOM根本緩和）
1GB・スワップ無しのため OOM が起きやすい。2GBのスワップを追加する:
```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-swap.conf
sudo sysctl -w vm.swappiness=10
free -h   # Swap 行が 2.0Gi になっていれば成功
```

### 2. 監視＋自己修復（落ちても即気づく・自動復旧）
`ops/health-check.sh` をサーバに導入し cron で1分毎に実行する。ダウン時に自動で `docker start` を試み、Webhook（Discord/Slack互換）に通知する。
```bash
# サーバ上（ubuntu）で
sudo install -m 755 ops/health-check.sh /usr/local/bin/mb-health-check
sudo tee /etc/default/mb-health-check >/dev/null <<'EOF'
HEALTHCHECK_URL=http://localhost/up
HEALTHCHECK_WEBHOOK_URL=        # 任意: Discord/Slack の incoming webhook URL
EOF
( crontab -l 2>/dev/null; echo '* * * * * /usr/local/bin/mb-health-check >> /var/log/mb-health-check.log 2>&1' ) | crontab -
```
加えて、外形監視（UptimeRobot / Better Stack 等の無料枠）で `https://mxchida.com/up` を外部からも監視するとサーバ自体の停止にも気づける。

### 3. コンテナのメモリ上限（巻き添えOOM防止）
`config/deploy.yml` の `servers.web.options` で `memory: 768m` / `memory-swap: 2g` を設定済み。**スワップ追加後**に `bin/kamal deploy` で反映される。実メモリ使用に応じて数値を調整する。

### 4. jemalloc（RubyのRSS削減）
`Dockerfile` で `LD_PRELOAD` により jemalloc を有効化済み（`MALLOC_CONF=dirty_decay_ms:1000,narenas:2,background_thread:true`）。次回ビルド・デプロイで反映。

### 5. 中期対応
- VPS の RAM を 2GB 以上へ増強（最も確実な根本解）
- 余裕が出たら SolidQueue を web コンテナから分離（`SOLID_QUEUE_IN_PUMA` を外し別プロセス/コンテナへ）

## メモリ状況の確認
```bash
free -h
docker stats --no-stream
```

## 障害履歴
### パスワード再設定メールの不達調査

- 本番のSMTP設定はREADMEの「メール送信の設定」を参照。環境変数または本番credentialsの `smtp` を使い、変更後に再デプロイする。
- GitHub ActionsからはRepository Secretsの `SMTP_USER_NAME`、`SMTP_PASSWORD`、`MAILER_FROM` をKamalへ渡す。ローカルからSSH接続できない場合でも、Actions側の接続可否はデプロイの結果で別途確認する。`/up` の成功だけではSMTP接続や送信の成功を判断しない。
- 登録済み管理者と一致するメールアドレスで申請する。未登録アドレスでも存在を明かさないため同じ完了表示になるが、メールは送られない。
- `SMTP_USER_NAME` / `SMTP_PASSWORD`（またはcredentials）と送信元の設定有無を確認する。秘密値や再設定トークンをログ・Issueに貼らない。
- `Net::SMTPAuthenticationError` は認証情報、接続タイムアウトはSMTPホスト・ポート・ネットワークを確認する。GoogleのアプリパスワードはGoogleアカウントのパスワード変更で失効する。
- 最終確認は登録済みアドレスで再設定を申請し、受信箱・迷惑メールフォルダ・リンク先のHTTPSホストを確認する。テスト成功と実際の受信確認は別に扱う。
- 2026-11-02調査: 本番でSMTPユーザー名・パスワード・送信元が未設定。直近の申請で再設定記録も生成されていなかった。設定コード・READMEを整備し、認証情報の登録と本番受信確認は別途必要。

- 2026-06-09: アプリコンテナが OOMKilled（ExitCode 137）。restart policy が `unless-stopped` でも再起動に失敗し、監視・アラートが無かったため約2週間ダウン（502）。本 Runbook 整備のきっかけ。

### 認証の保護（2026-11-08）

- Railsを8.1.4.1に更新し、2026-11-04公開のセキュリティ修正を適用。依存検査は最新のruby-advisory-dbで実行する。
- ログインはIP単位で3分10回、再設定メール申請は15分5回まで。超過はHTTP 429。時間経過で再試行できる。本番ではSolid Cacheのcache DBが必要。制限解除のために全キャッシュを消去しない。
- パスワード変更・再設定後は他のブラウザーのログインが無効になる。初回デプロイ時も全管理者に再ログインが必要。
- 新規本番環境の初回seedには `INITIAL_ADMIN_EMAIL` / `INITIAL_ADMIN_USER_ID` / `INITIAL_ADMIN_PASSWORD`（16文字以上）をseedプロセスへ渡す。秘密値をコマンド履歴・ソースコードへ記録しない。既存管理者がいれば作成をスキップする。
- seedはサイト設定・サンプル記事も作成するため、既存環境の管理者復旧には使用しない。今回の修正は既存のパスワードを変更しない。
- 回帰確認: `bundle exec rails test test/integration/authentication_security_test.rb test/services/initial_admin_seeder_test.rb test/helpers/application_helper_test.rb`。
- Markdownは危険なプロトコルのリンクを出力せず、コードブロックの言語指定をHTMLエスケープします。
- 検証結果（2026-11-08）: `bundle exec rails test:all` は396件・1460 assertions、失敗/エラー/スキップ0。bundler-audit・npm auditは脆弱性0件、Brakemanは警告0件。`npm run lint` はエラー0件（既存JS警告3件）。専用ブランチでのローカル検証であり、本番反映は別途必要。

### 初回seed失敗後の復旧

新規環境の `db:prepare` はスキーマ作成後にseedを呼ぶため、認証情報不足でseedが失敗してもスキーマは残ります。次の `db:prepare` はseedを再実行しない場合があります。

1. GitHub Repository Secretsに `INITIAL_ADMIN_EMAIL` / `INITIAL_ADMIN_USER_ID` / `INITIAL_ADMIN_PASSWORD`（16文字以上）を登録する。ローカルKamalではパスワード管理ツール等から同名の環境変数を設定する。値をコマンド引数や履歴へ書かない。
2. 同じ設定を渡して再デプロイする。ActionsのDeployステップから `.kamal/secrets` と `env.secret` を経てコンテナーへ渡る。未設定のbootstrap変数はKamalの必須シークレットに含めないので、既存環境の通常デプロイは影響を受けない。
3. 初回構築途中のDBであり、既存の記事・設定を持たないことを確認してから `bundle exec kamal app exec --reuse "bin/rails db:seed"` を実行する。起動済みコンテナーへ渡した認証情報を使う。既存ブログの管理者復旧にこのコマンドを使わない。
4. 管理者ログインを確認する。初期作成後はbootstrap用Repository Secretsを削除して再デプロイできる。既存管理者は追加・上書きされない。

### PR #217 レビュー対応

- `password_digest` が失われた管理者のCookieを破棄し、500ではなくログインへ戻す。
- 同じブラウザーでパスワード変更後に別タブの管理フォームを送る場合、認証が必要なno-storeのCSRFエンドポイントから新しいトークンを取得する。古いトークンとトークンなしのPOSTは引き続き拒否する。セッション再生成も維持する。
- 確認コマンド: `bundle exec rails test test/integration/authentication_security_test.rb test/services/initial_admin_seeder_test.rb test/lib/bootstrap_deployment_test.rb test/system/password_change_csrf_playwright_test.rb`。
- レビュー対応後の全体検証: 401件・1514 assertions、失敗/エラー/スキップ0。lintエラー0、Brakeman警告0。
