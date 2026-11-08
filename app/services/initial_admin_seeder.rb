class InitialAdminSeeder
  # Bootstrap only an empty installation; production must supply its own secrets.
  def self.call(environment: Rails.env, env: ENV)
    # Never add a known account to an installation with existing administrators.
    return if Admin.exists?

    if environment.to_s == "production"
      email = env["INITIAL_ADMIN_EMAIL"]
      user_id = env["INITIAL_ADMIN_USER_ID"]
      password = env["INITIAL_ADMIN_PASSWORD"]
      unless email.present? && user_id.present? && password.to_s.length >= 16
        raise ArgumentError, "本番の初期管理者には INITIAL_ADMIN_EMAIL / INITIAL_ADMIN_USER_ID / INITIAL_ADMIN_PASSWORD（16文字以上）が必要です"
      end
    else
      email = "admin@example.com"
      user_id = "admin"
      password = "development-password"
    end

    Admin.create!(email: email, user_id: user_id, password: password,
                  password_confirmation: password)
  end
end
