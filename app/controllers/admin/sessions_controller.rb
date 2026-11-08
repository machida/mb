class Admin::SessionsController < Admin::BaseController
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { head :too_many_requests }
  skip_before_action :require_admin, only: [ :new, :create ]
  def new
  end

  def create
    admin = Admin.find_by(email: params[:email])

    if admin && admin.authenticate(params[:password])
      # セッション固定化攻撃対策: ログイン時にセッションIDを再生成
      start_admin_session(admin)
      redirect_to root_path, notice: "ログインしました"
    else
      flash.now[:alert] = "メールアドレスまたはパスワードが間違っています"
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "ログアウトしました"
  end
end
