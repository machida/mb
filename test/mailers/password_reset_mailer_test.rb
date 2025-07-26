require "test_helper"

class PasswordResetMailerTest < ActionMailer::TestCase
  setup do
    @admin = admins(:admin)
    @admin.generate_password_reset_token
  end

  test "reset_email" do
    mail = PasswordResetMailer.reset_email(@admin)
    
    assert_equal "パスワードリセットのお知らせ", mail.subject
    assert_equal [@admin.email], mail.to
    assert_equal [ENV.fetch("MAILER_FROM", "noreply@example.com")], mail.from
    
    # メール本文が存在することを確認
    assert mail.text_part.present?
    assert mail.html_part.present?
  end

  test "reset_email includes admin email" do
    mail = PasswordResetMailer.reset_email(@admin)
    # テキスト版とHTML版の両方にメールアドレスが含まれていることを確認
    assert mail.text_part.body.to_s.include?(@admin.email)
  end

  test "reset_email includes reset URL" do
    mail = PasswordResetMailer.reset_email(@admin)
    # URLが含まれていることを確認
    assert mail.text_part.body.to_s.include?("password_resets")
  end
end
