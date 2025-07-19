class Admin::PasswordsController < Admin::BaseController
  before_action :set_admin

  def edit
  end

  def update
    # パスワード変更時は必須チェック
    if password_params[:password].blank?
      @admin.errors.add(:password, "を入力してください")
      render :edit, status: :unprocessable_entity
      return
    end

    if password_params[:password] != password_params[:password_confirmation]
      @admin.errors.add(:password_confirmation, "が一致しません")
      render :edit, status: :unprocessable_entity
      return
    end

    # password_changed_atを現在時刻に設定
    if @admin.update(password_params.merge(password_changed_at: Time.current))
      redirect_to edit_admin_profile_path, notice: "パスワードが正常に更新されました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_admin
    @admin = current_admin
  end

  def password_params
    params.require(:admin).permit(:password, :password_confirmation)
  end
end
