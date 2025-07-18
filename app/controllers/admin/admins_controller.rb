class Admin::AdminsController < Admin::BaseController
  def index
    @admins = Admin.all.order(:user_id)
  end

  def new
    @admin = Admin.new
  end

  def create
    @admin = Admin.new(admin_params)
    
    if @admin.save
      redirect_with_success(admin_admins_path, "管理者を作成しました")
    else
      render_with_errors :new, @admin
    end
  end

  def show
    @admin = Admin.find(params[:id])
  end

  def edit
    @admin = Admin.find(params[:id])
  end

  def update
    @admin = Admin.find(params[:id])
    
    if @admin.update(admin_params)
      redirect_with_success(admin_admins_path, "管理者情報を更新しました")
    else
      render_with_errors :edit, @admin
    end
  end

  def destroy
    @admin = Admin.find(params[:id])
    
    if @admin == current_admin
      set_error_message("自分自身を削除することはできません")
      redirect_to admin_admins_path
      return
    end
    
    @admin.destroy
    redirect_with_success(admin_admins_path, "管理者を削除しました")
  end

  private

  def admin_params
    if params[:admin] && params[:admin][:password].blank?
      params.require(:admin).permit(:email, :user_id)
    else
      params.require(:admin).permit(:email, :user_id, :password, :password_confirmation)
    end
  end
end