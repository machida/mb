class Admin::PasswordResetsController < ApplicationController
  layout "admin"
  before_action :find_admin_by_token, only: [ :show, :update ]

  def new
  end

  def create
    @admin = Admin.find_by(email: params[:email])

    if @admin
      @admin.generate_password_reset_token
      PasswordResetMailer.reset_email(@admin).deliver_now
      redirect_to admin_login_path, notice: "パスワードリセット用のメールを送信しました。メールをご確認ください。"
    else
      # セキュリティ上、メールアドレスの存在有無を明かさない
      redirect_to admin_login_path, notice: "パスワードリセット用のメールを送信しました。メールをご確認ください。"
    end
  end

  def show
    # パスワードリセットフォームを表示
  end

  def update
    if params[:admin][:password].blank?
      flash.now[:alert] = "パスワードを入力してください"
      render :show, status: :unprocessable_entity
      return
    end

    if params[:admin][:password] != params[:admin][:password_confirmation]
      flash.now[:alert] = "パスワードと確認用パスワードが一致しません"
      render :show, status: :unprocessable_entity
      return
    end

    if params[:admin][:password].length < 8
      flash.now[:alert] = "パスワードは8文字以上で設定してください"
      render :show, status: :unprocessable_entity
      return
    end

    if @admin.reset_password(params[:admin][:password])
      # セッション固定化攻撃対策: パスワードリセット後に自動ログイン
      reset_session
      session[:admin_id] = @admin.id
      redirect_to root_path, notice: "パスワードが正常に変更されました。ログインしました。"
    else
      flash.now[:alert] = "パスワードの変更に失敗しました"
      render :show, status: :unprocessable_entity
    end
  end

  private

  def find_admin_by_token
    token = params[:token]
    @admin = Admin.find_by_password_reset_token(token)

    unless @admin
      redirect_to admin_login_path, alert: "無効なリンクです。パスワードリセットリンクの有効期限が切れているか、既に使用済みの可能性があります。"
    end
  end
end
