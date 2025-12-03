require "application_playwright_test_case"

class AdminManagementPlaywrightTest < ApplicationPlaywrightTestCase
  def setup
    super
    
    # 確実にテスト用管理者をクリーンアップ
    Admin.where(email: ["test_admin_main@example.com", "test_new_admin@example.com"]).destroy_all
    
    # テスト用の管理者を作成（フィクスチャと重複しないemailを使用）
    @admin = Admin.create!(
      email: "test_admin_main@example.com",
      user_id: "test_admin_main",
      password: TEST_ADMIN_PASSWORD,
      password_confirmation: TEST_ADMIN_PASSWORD,
      password_changed_at: Time.current  # 既にパスワード変更済み
    )
    
    # 初期パスワードのままの管理者を作成
    @new_admin = Admin.create!(
      email: "test_new_admin@example.com",
      user_id: "test_new_admin",
      password: TEST_ADMIN_PASSWORD,
      password_confirmation: TEST_ADMIN_PASSWORD
      # password_changed_at は nil のまま（初期パスワード状態）
    )
  end

  test "admin can view admin list" do
    login_as_admin(@admin)
    
    @page.goto("http://localhost:#{@server_port}/admin/admins")
    @page.wait_for_load_state(state: 'networkidle')
    
    # 管理者一覧が表示される
    assert @page.locator(".spec--admins-list").visible?
    assert @page.locator(".spec--admin-user-id", hasText: "test_admin_main").visible?
    assert @page.locator(".spec--admin-user-id", hasText: "test_new_admin").visible?
  end

  test "admin can create new admin" do
    login_as_admin(@admin)
    
    # 新規管理者追加ページに直接アクセス
    @page.goto("http://localhost:#{@server_port}/admin/admins/new")
    @page.wait_for_load_state(state: 'networkidle')
    
    # フォーム要素の存在を確認してからフィルイン
    @page.wait_for_selector(".spec--admin-user-id-input", timeout: 10000)
    @page.wait_for_selector(".spec--admin-email-input", timeout: 10000)
    @page.wait_for_selector(".spec--admin-password-input", timeout: 10000)
    @page.wait_for_selector(".spec--create-admin-button", timeout: 10000)
    
    # フォームに入力
    @page.fill(".spec--admin-user-id-input", "testadmin")
    @page.fill(".spec--admin-email-input", "testadmin@example.com") 
    @page.fill(".spec--admin-password-input", "password123")
    @page.fill(".spec--admin-password-confirmation-input", "password123")
    
    # 管理者を追加
    @page.click(".spec--create-admin-button")
    
    # フォーム送信を待機（URLが変わるまで待つ）
    @page.wait_for_url("**/admin/admins", timeout: 10000)
    @page.wait_for_load_state(state: 'networkidle')
    
    # 成功メッセージが表示される
    assert @page.locator("text=管理者「testadmin」を追加しました").visible?
    
    # 管理者一覧に新しい管理者が表示される
    assert @page.locator(".spec--admin-user-id", hasText: "testadmin").visible?
  end

  test "new admin sees password change notice" do
    login_as_admin(@new_admin)
    
    @page.goto("http://localhost:#{@server_port}/admin/articles")
    @page.wait_for_load_state(state: 'networkidle')
    
    # パスワード変更通知が表示される
    notice_element = @page.locator(".spec--password-change-notice")
    assert notice_element.visible?, "Password change notice should be visible"
    assert @page.locator("text=セキュリティ強化のため、初期パスワードから変更してください").visible?
    
    # パスワード変更リンクをクリック
    @page.click(".spec--change-password-link")
    @page.wait_for_load_state(state: 'networkidle')
    
    # パスワード変更ページに遷移
    @page.wait_for_url("**/admin/password/edit", timeout: 10000)
    assert @page.locator(".spec--password-edit-title").visible?
  end

  test "admin can delete another admin without articles" do
    # Ensure new admin has no articles
    Article.where(author: @new_admin.user_id).destroy_all
    
    login_as_admin(@admin)
    
    @page.goto("http://localhost:#{@server_port}/admin/admins")
    @page.wait_for_load_state(state: 'networkidle')
    
    # 削除対象の管理者の詳細ページへ（詳細ボタンをクリック）
    show_buttons = @page.locator(".spec--admin-show-button")
    show_buttons.nth(1).click()  # Click the second "詳細" button for test_new_admin
    @page.wait_for_load_state(state: 'networkidle')
    
    # 管理者を削除（記事がない場合）
    @page.on("dialog", lambda { |dialog| 
      Rails.logger.debug "Dialog appeared: #{dialog.message}"
      dialog.accept 
    })
    @page.click(".spec--simple-delete-button")
    
    # Wait for either redirect to index or stay on page with error
    begin
      @page.wait_for_url("**/admin/admins", timeout: 5000)
    rescue Playwright::TimeoutError
      Rails.logger.debug "No redirect - might have error. Current URL: #{@page.url}"
      Rails.logger.debug "Page content: #{@page.text_content('body')}"
    end
    @page.wait_for_load_state(state: 'networkidle')
    
    # 削除が成功したかをadmin一覧から確認
    admin_ids = @page.locator(".spec--admin-user-id").all_text_contents
    Rails.logger.debug "Admin IDs on page: #{admin_ids}"
    Rails.logger.debug "Current URL: #{@page.url}"
    
    # Check that test_new_admin is no longer in the list
    assert_not admin_ids.include?("test_new_admin"), "test_new_admin should be deleted from admin list"
  end

  test "admin can transfer articles when deleting admin" do
    # 削除対象の管理者に記事を追加
    test_article = Article.create!(
      title: "Test Article",
      body: "Test content",
      author: @new_admin.user_id,
      draft: false
    )
    Rails.logger.debug "Created article #{test_article.id} for admin #{@new_admin.user_id}"
    Rails.logger.debug "Admin #{@new_admin.user_id} has #{@new_admin.articles.count} articles"
    
    login_as_admin(@admin)
    
    # 削除対象の管理者の詳細ページへ（直接URLアクセス）
    @page.goto("http://localhost:#{@server_port}/admin/admins/#{@new_admin.id}")
    @page.wait_for_load_state(state: 'networkidle')
    
    # 記事移譲オプションを選択
    Rails.logger.debug "Looking for transfer radio. Page content: #{@page.locator('body').text_content}"
    Rails.logger.debug "Admin has articles: #{@new_admin.reload.articles.exists?}"
    
    transfer_radio = @page.locator(".spec--transfer-radio")
    assert transfer_radio.visible?, "Transfer radio should be visible when admin has articles"
    transfer_radio.click()
    @page.locator(".spec--target-admin-select").select_option(value: @admin.id.to_s)
    
    # 管理者を削除
    @page.click(".spec--confirm-delete-button")
    @page.wait_for_load_state(state: 'networkidle')
    
    # Wait for redirect to index page and verify deletion
    begin
      @page.wait_for_url("**/admin/admins", timeout: 10000)
    rescue Playwright::TimeoutError
      Rails.logger.debug "No redirect to admin index. Current URL: #{@page.url}"
    end
    
    # 記事の著者が変更されている
    article = Article.find_by(title: "Test Article")
    assert_equal @admin.user_id, article.author, "Article author should be transferred to target admin"
    
    # 管理者が削除されている
    assert_not Admin.exists?(@new_admin.id), "test_new_admin should be deleted"
  end

  test "cannot delete last admin" do
    # 他の管理者をすべて削除して最後の一人にする
    Admin.where.not(id: @admin.id).destroy_all
    
    login_as_admin(@admin)
    
    @page.goto("http://localhost:#{@server_port}/admin/admins")
    @page.wait_for_load_state(state: 'networkidle')
    
    # 削除ボタンが表示されない
    delete_buttons = @page.locator(".spec--admin-delete-button")
    assert_equal 0, delete_buttons.count, "Delete button should not be visible for last admin"
    
    # 詳細ページでも削除不可
    @page.wait_for_selector(".spec--admin-show-button", timeout: 5000)
    @page.click(".spec--admin-show-button")
    @page.wait_for_url("**/admin/admins/*", timeout: 10000)
    @page.wait_for_load_state(state: 'networkidle')
    
    # Debug: check if admin is actually last admin
    Rails.logger.debug "Admin count: #{Admin.count}"
    Rails.logger.debug "Is last admin: #{@admin.reload.last_admin?}"
    
    cannot_delete_button = @page.locator(".spec--cannot-delete-button")
    assert cannot_delete_button.visible?, "Cannot delete button should be visible for last admin. Page content: #{@page.text_content('body')}"
    assert @page.locator("text=最後の管理者は削除できません").visible?
  end

  test "password change notice disappears after changing password" do
    login_as_admin(@new_admin)
    
    @page.goto("http://localhost:#{@server_port}/admin/articles")
    @page.wait_for_load_state(state: 'networkidle')
    
    # パスワード変更通知が表示される
    assert @page.locator(".spec--password-change-notice").visible?
    
    # パスワード変更
    @page.click(".spec--change-password-link")
    @page.wait_for_load_state(state: 'networkidle')
    
    # Wait for form elements to be available
    @page.wait_for_selector(".spec--password-input", timeout: 10000)
    @page.fill(".spec--password-input", "newpassword123")
    @page.fill(".spec--password-confirmation-input", "newpassword123")

    # Submit form and wait for redirect
    @page.click(".spec--password-change-button")
    @page.wait_for_load_state(state: 'networkidle')
    
    # セッションとデータベースの更新を確実にするため少し待機
    sleep 0.5
    
    # 管理画面に戻る
    @page.goto("http://localhost:#{@server_port}/admin/articles")
    @page.wait_for_load_state(state: 'networkidle')
    
    # データベース状態を確認
    @new_admin.reload
    Rails.logger.debug "Admin password_changed_at after update: #{@new_admin.password_changed_at}"
    Rails.logger.debug "Admin needs_password_change?: #{@new_admin.needs_password_change?}"
    
    # パスワード変更通知が消える
    notice_elements = @page.locator(".spec--password-change-notice")
    if notice_elements.count > 0
      Rails.logger.debug "Password change notice still visible. Page content: #{@page.locator('body').text_content}"
    end
    assert_equal 0, notice_elements.count, "Password change notice should disappear after password change"
  end
end