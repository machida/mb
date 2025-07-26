# SMTP設定ガイド (VPS/Kamalデプロイ用)

パスワードリセット機能を有効にするためのSMTP設定手順

## 1. 環境変数の設定

以下の環境変数をKamal設定または本番サーバーで設定してください：

```bash
# アプリケーションのホスト名
APP_HOST=yourdomain.com

# メール送信者アドレス
MAILER_FROM=noreply@yourdomain.com
```

## 2. Rails Credentialsの設定

SMTP認証情報を安全に保存するため、以下のコマンドでcredentialsを編集：

```bash
EDITOR=vim rails credentials:edit
```

以下の形式でSMTP設定を追加：

```yaml
smtp:
  user_name: your-smtp-username
  password: your-smtp-password
  address: smtp.gmail.com  # または使用するSMTPサーバー
  port: 587
  authentication: plain
```

## 3. 推奨SMTPプロバイダー

### Gmail (推奨)
```yaml
smtp:
  user_name: youremail@gmail.com
  password: your-app-password  # 2段階認証有効時はアプリパスワード
  address: smtp.gmail.com
  port: 587
  authentication: plain
```

### SendGrid
```yaml
smtp:
  user_name: apikey
  password: your-sendgrid-api-key
  address: smtp.sendgrid.net
  port: 587
  authentication: plain
```

### Mailgun
```yaml
smtp:
  user_name: postmaster@yourdomain.mailgun.org
  password: your-mailgun-password
  address: smtp.mailgun.org
  port: 587
  authentication: plain
```

## 4. Kamalでのデプロイ設定

`.kamal/deploy.yml`に環境変数を追加：

```yaml
env:
  clear:
    APP_HOST: yourdomain.com
    MAILER_FROM: noreply@yourdomain.com
```

## 5. テスト方法

本番環境でのメール送信テスト：

```bash
# Railsコンソールで実行
rails console

# テストメール送信
admin = Admin.first
admin.generate_password_reset_token
PasswordResetMailer.reset_email(admin).deliver_now
```

## 6. セキュリティ考慮事項

- **アプリパスワード使用**: Gmail等では2段階認証とアプリパスワードを使用
- **環境変数保護**: Credentials以外の機密情報は環境変数で管理
- **TLS有効化**: `enable_starttls_auto: true` で暗号化通信を強制
- **レート制限**: SMTPプロバイダーの送信制限を確認

## 7. トラブルシューティング

### メールが送信されない場合
1. Rails logs確認: `tail -f log/production.log`
2. SMTP認証情報の確認
3. ファイアウォール設定確認 (587, 465ポート)
4. SMTPプロバイダーの制限確認

### メールが届かない場合
1. スパムフォルダ確認
2. SPF/DKIMレコード設定 (独自ドメイン使用時)
3. 送信者レピュテーション確認

## 8. 開発環境での確認

開発環境では`:test`配信方法を使用しており、実際のメール送信は行われません。
開発中にメール内容を確認したい場合は、Railsコンソールで以下を実行：

```bash
rails console
ActionMailer::Base.deliveries.last  # 最後に送信されたメールの内容確認
```