require "application_playwright_test_case"

class PasswordChangeCsrfPlaywrightTest < ApplicationPlaywrightTestCase
  # Enable real CSRF checks only in this test's separately launched Rails server.
  def setup_rails_server
    previous = ENV["TEST_CSRF_PROTECTION"]
    ENV["TEST_CSRF_PROTECTION"] = "true"
    super
  ensure
    ENV["TEST_CSRF_PROTECTION"] = previous
  end

  test "an open article survives password rotation while stale tokens remain rejected" do
    admin = login_as_admin
    article = Article.create!(title: "Before rotation", body: "Original body", author: admin.user_id, draft: true)
    @page.goto("http://localhost:#{@server_port}/admin/articles/#{article.id}/edit")
    @page.fill(TITLE_INPUT, "Unsaved title retained")
    old_token = @page.locator('meta[name="csrf-token"]').first.get_attribute("content")

    password_page = @context.new_page
    password_page.goto("http://localhost:#{@server_port}/admin/password/edit")
    password_page.fill(PASSWORD_INPUT, "changed-password-123")
    password_page.fill(PASSWORD_CONFIRMATION_INPUT, "changed-password-123")
    password_page.click(PASSWORD_CHANGE_BUTTON)
    password_page.wait_for_url(/\/admin\/profile\/edit/)

    # Bypass the Turbo refresh to prove stale and missing tokens still fail.
    [ old_token, "" ].each do |token|
      status = @page.evaluate(<<~JS, arg: token)
        async token => {
          const response = await fetch('/admin/articles/preview', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': token },
            body: JSON.stringify({ content: 'test' })
          });
          return response.status;
        }
      JS
      assert_equal 422, status
    end

    @page.click(UPDATE_BUTTON)
    @page.wait_for_url(/\/article\//)
    assert_equal "Unsaved title retained", article.reload.title
    assert admin.reload.authenticate("changed-password-123")
  ensure
    password_page&.close
  end
end
