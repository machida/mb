class Admin::SessionsController < Admin::BaseController
  skip_before_action :require_admin, only: [:new, :create]
  def new
  end

  def create
    admin = Admin.find_by(email: params[:email])
    
    if admin && admin.authenticate(params[:password])
      session[:admin_id] = admin.id
      redirect_to root_path, notice: "ログインしました"
    else
      flash.now[:alert] = "メールアドレスまたはパスワードが間違っています"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:admin_id] = nil
    redirect_to root_path, notice: "ログアウトしました"
  end
end
