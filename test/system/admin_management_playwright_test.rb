require "application_playwright_test_case"

class AdminManagementPlaywrightTest < ApplicationPlaywrightTestCase
  def setup
    super
    # 初期管理者を作成
    @admin = Admin.create!(
      email: "admin@example.com",
      user_id: "admin",
      password: "password123",
      password_confirmation: "password123",
      password_changed_at: Time.current  # 既にパスワード変更済み
    )
    
    # 初期パスワードのままの管理者を作成
    @new_admin = Admin.create!(
      email: "newadmin@example.com",
      user_id: "newadmin",
      password: "initial123",
      password_confirmation: "initial123"
      # password_changed_at は nil のまま
    )
  end

  test "admin can view admin list" do
    login_as_admin(@admin)
    
    @page.goto("#{@base_url}/admin/admins")
    @page.wait_for_load_state("networkidle")
    
    # 管理者一覧が表示される
    assert @page.locator(".spec--admins-list").visible?
    assert @page.locator(".spec--admin-user-id").filter(has_text: "admin").visible?
    assert @page.locator(".spec--admin-user-id").filter(has_text: "newadmin").visible?
  end

  test "admin can create new admin" do
    login_as_admin(@admin)
    
    @page.goto("#{@base_url}/admin/admins")
    @page.wait_for_load_state("networkidle")
    
    # 新規管理者追加ページへ
    @page.click(".spec--new-admin-link")
    @page.wait_for_load_state("networkidle")
    
    # フォームに入力
    @page.fill(".spec--admin-user-id-input", "testadmin")
    @page.fill(".spec--admin-email-input", "testadmin@example.com")
    @page.fill(".spec--admin-password-input", "password123")
    @page.fill(".spec--admin-password-confirmation-input", "password123")
    
    # 管理者を追加
    @page.click(".spec--create-admin-button")
    @page.wait_for_load_state("networkidle")
    
    # 成功メッセージが表示される
    assert @page.locator("text=管理者「testadmin」を追加しました").visible?
    
    # 管理者一覧に新しい管理者が表示される
    assert @page.locator(".spec--admin-user-id").filter(has_text: "testadmin").visible?
  end

  test "new admin sees password change notice" do
    login_as_admin(@new_admin)
    
    @page.goto("#{@base_url}/admin/articles")
    @page.wait_for_load_state("networkidle")
    
    # パスワード変更通知が表示される
    assert @page.locator(".spec--password-change-notice").visible?
    assert @page.locator("text=セキュリティ強化のため、初期パスワードから変更してください").visible?
    
    # パスワード変更リンクをクリック
    @page.click(".spec--change-password-link")
    @page.wait_for_load_state("networkidle")
    
    # パスワード変更ページに遷移
    assert @page.locator(".spec--password-edit-title").visible?
  end

  test "admin can delete another admin without articles" do
    login_as_admin(@admin)
    
    @page.goto("#{@base_url}/admin/admins")
    @page.wait_for_load_state("networkidle")
    
    # 削除対象の管理者の詳細ページへ
    @page.locator(".spec--admin-user-id").filter(has_text: "newadmin").click()
    @page.wait_for_load_state("networkidle")
    
    # 管理者を削除（記事がない場合）
    @page.on("dialog", lambda { |dialog| dialog.accept })
    @page.click(".spec--simple-delete-button")
    @page.wait_for_load_state("networkidle")
    
    # 削除成功メッセージが表示される
    assert @page.locator("text=管理者「newadmin」を削除しました").visible?
    
    # 管理者一覧から削除された管理者が消える
    assert_not @page.locator(".spec--admin-user-id").filter(has_text: "newadmin").visible?
  end

  test "admin can transfer articles when deleting admin" do
    # 削除対象の管理者に記事を追加
    Article.create!(
      title: "Test Article",
      body: "Test content",
      author: @new_admin.user_id,
      draft: false
    )
    
    login_as_admin(@admin)
    
    @page.goto("#{@base_url}/admin/admins")
    @page.wait_for_load_state("networkidle")
    
    # 削除対象の管理者の詳細ページへ
    @page.locator(".spec--admin-user-id").filter(has_text: "newadmin").click()
    @page.wait_for_load_state("networkidle")
    
    # 記事移譲オプションを選択
    @page.click(".spec--transfer-radio")
    @page.select_option(".spec--target-admin-select", @admin.id.to_s)
    
    # 管理者を削除
    @page.click(".spec--confirm-delete-button")
    @page.wait_for_load_state("networkidle")
    
    # 削除成功メッセージが表示される
    assert @page.locator("text=記事を「admin」に移譲し、管理者「newadmin」を削除しました").visible?
    
    # 記事の著者が変更されている
    article = Article.find_by(title: "Test Article")
    assert_equal @admin.user_id, article.author
  end

  test "cannot delete last admin" do
    # 他の管理者を削除して最後の一人にする
    @new_admin.destroy
    
    login_as_admin(@admin)
    
    @page.goto("#{@base_url}/admin/admins")
    @page.wait_for_load_state("networkidle")
    
    # 削除ボタンが表示されない
    assert_not @page.locator(".spec--admin-delete-button").visible?
    
    # 詳細ページでも削除不可
    @page.locator(".spec--admin-user-id").filter(has_text: "admin").click()
    @page.wait_for_load_state("networkidle")
    
    assert @page.locator(".spec--cannot-delete-button").visible?
    assert @page.locator("text=最後の管理者は削除できません").visible?
  end

  test "password change notice disappears after changing password" do
    login_as_admin(@new_admin)
    
    @page.goto("#{@base_url}/admin/articles")
    @page.wait_for_load_state("networkidle")
    
    # パスワード変更通知が表示される
    assert @page.locator(".spec--password-change-notice").visible?
    
    # パスワード変更
    @page.click(".spec--change-password-link")
    @page.wait_for_load_state("networkidle")
    
    @page.fill(".spec--password-input", "newpassword123")
    @page.fill(".spec--password-confirmation-input", "newpassword123")
    @page.click(".spec--password-change-button")
    @page.wait_for_load_state("networkidle")
    
    # 管理画面に戻る
    @page.goto("#{@base_url}/admin/articles")
    @page.wait_for_load_state("networkidle")
    
    # パスワード変更通知が消える
    assert_not @page.locator(".spec--password-change-notice").visible?
  end
end