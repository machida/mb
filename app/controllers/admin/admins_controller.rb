class Admin::AdminsController < Admin::BaseController
  before_action :set_admin, only: [:show, :destroy]

  def index
    @admins = Admin.all.order(:user_id)
  end

  def show
  end

  def new
    @admin = Admin.new
  end

  def create
    @admin = Admin.new(admin_params)
    
    if @admin.save
      redirect_to admin_admins_path, notice: "管理者「#{@admin.user_id}」を追加しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if @admin.last_admin?
      redirect_to admin_admins_path, alert: "最後の管理者は削除できません。"
      return
    end

    if @admin.articles.exists?
      redirect_to admin_admin_path(@admin), alert: "この管理者には記事が存在します。先に記事の処理を行ってください。"
      return
    end

    @admin.destroy
    
    if current_admin == @admin
      session[:admin_id] = nil
      redirect_to admin_login_path, notice: "アカウントを削除しました。"
    else
      redirect_to admin_admins_path, notice: "管理者「#{@admin.user_id}」を削除しました。"
    end
  end

  def confirm_delete
    @admin = Admin.find(params[:id])
    
    if @admin.last_admin?
      redirect_to admin_admins_path, alert: "最後の管理者は削除できません。"
      return
    end

    @other_admins = Admin.where.not(id: @admin.id).order(:user_id)
    @articles_count = @admin.articles.count
  end

  def process_delete
    @admin = Admin.find(params[:id])
    action_type = params[:action_type]
    
    case action_type
    when "transfer"
      target_admin = Admin.find(params[:target_admin_id])
      @admin.transfer_articles_to(target_admin)
      message = "記事を「#{target_admin.user_id}」に移譲し、管理者「#{@admin.user_id}」を削除しました。"
    when "delete_articles"
      @admin.delete_articles
      message = "記事を削除し、管理者「#{@admin.user_id}」を削除しました。"
    else
      redirect_to admin_admin_path(@admin), alert: "無効な操作です。"
      return
    end

    @admin.destroy
    
    if current_admin == @admin
      session[:admin_id] = nil
      redirect_to admin_login_path, notice: message
    else
      redirect_to admin_admins_path, notice: message
    end
  end

  private

  def set_admin
    @admin = Admin.find(params[:id])
  end

  def admin_params
    params.require(:admin).permit(:email, :user_id, :password, :password_confirmation)
  end
end