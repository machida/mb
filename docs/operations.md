# 運用 Runbook（本番）

本番は Kamal で 1台の VPS にデプロイしています。本書は障害対応・再発防止のための手順をまとめたものです。

## 構成サマリ
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
- 2026-06-09: アプリコンテナが OOMKilled（ExitCode 137）。restart policy が `unless-stopped` でも再起動に失敗し、監視・アラートが無かったため約2週間ダウン（502）。本 Runbook 整備のきっかけ。
