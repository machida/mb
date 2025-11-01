class Admin::ProfilesController < Admin::BaseController
  def edit
    @admin = current_admin
  end

  def update
    @admin = current_admin

    if @admin.update(profile_params)
      redirect_to edit_admin_profile_path, notice: "プロフィールを更新しました。"
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def profile_params
    params.require(:admin).permit(:email, :user_id, :theme_color)
  end
end
