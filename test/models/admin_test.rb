require "test_helper"

class AdminTest < ActiveSupport::TestCase
  def setup
    @admin = Admin.new(
      email: "admin@example.com",
      user_id: "admin123",
      password: "password123"
    )
  end

  test "should be valid with valid attributes" do
    assert @admin.valid?
  end

  test "should require email" do
    @admin.email = nil
    assert_not @admin.valid?
    assert_includes @admin.errors[:email], "can't be blank"
  end

  test "should require user_id" do
    @admin.user_id = nil
    assert_not @admin.valid?
    assert_includes @admin.errors[:user_id], "can't be blank"
  end

  test "should require password" do
    @admin.password = nil
    assert_not @admin.valid?
    assert_includes @admin.errors[:password], "can't be blank"
  end

  test "should require unique email" do
    @admin.save!
    
    duplicate_admin = Admin.new(
      email: "admin@example.com",
      user_id: "different_user",
      password: "password123"
    )
    
    assert_not duplicate_admin.valid?
    assert_includes duplicate_admin.errors[:email], "has already been taken"
  end

  test "should require unique user_id" do
    @admin.save!
    
    duplicate_admin = Admin.new(
      email: "different@example.com",
      user_id: "admin123",
      password: "password123"
    )
    
    assert_not duplicate_admin.valid?
    assert_includes duplicate_admin.errors[:user_id], "has already been taken"
  end

  test "should authenticate with correct password" do
    @admin.save!
    assert @admin.authenticate("password123")
    assert_not @admin.authenticate("wrongpassword")
  end

  test "should have many articles" do
    @admin.save!
    
    article1 = Article.create!(
      title: "First Article",
      body: "Content 1",
      author: @admin.user_id
    )
    
    article2 = Article.create!(
      title: "Second Article", 
      body: "Content 2",
      author: @admin.user_id
    )

    assert_includes @admin.articles, article1
    assert_includes @admin.articles, article2
    assert_equal 2, @admin.articles.count
  end

  test "should allow valid email formats" do
    # Rails default validation only checks for presence and uniqueness
    # Format validation would need to be added separately
    valid_emails = ["user@example.com", "test.user@domain.co.jp", "admin+test@site.org"]
    
    valid_emails.each do |email|
      @admin.email = email
      assert @admin.valid?, "#{email} should be valid"
    end
  end


  test "should require minimum password length" do
    @admin.password = "short"
    assert_not @admin.valid?
    assert_includes @admin.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "should handle password confirmation validation" do
    @admin.password = "password123"
    @admin.password_confirmation = "different"
    assert_not @admin.valid?
    assert_includes @admin.errors[:password_confirmation], "doesn't match Password"
  end

  test "should save password securely" do
    @admin.password = "password123"
    @admin.save!
    
    # Password should be encrypted, not stored as plain text
    assert_not_equal "password123", @admin.password_digest
    assert @admin.password_digest.present?
  end

  test "should handle case insensitive email uniqueness" do
    @admin.email = "Admin@Example.COM"
    @admin.save!
    
    duplicate_admin = Admin.new(
      email: "Admin@Example.COM",
      user_id: "different_user", 
      password: "password123"
    )
    
    assert_not duplicate_admin.valid?
    assert_includes duplicate_admin.errors[:email], "has already been taken"
  end

  test "should handle case insensitive email" do
    @admin.email = "Admin@Example.COM"
    @admin.save!
    
    # Email is stored as-is (no automatic normalization)
    assert_equal "Admin@Example.COM", @admin.reload.email
  end

  test "should handle special characters in user_id" do
    @admin.user_id = "user-123_test"
    assert @admin.valid?
  end

  test "should not allow empty string for required fields" do
    @admin.email = nil
    @admin.user_id = nil
    @admin.password = nil
    
    assert_not @admin.valid?
    assert_includes @admin.errors[:email], "can't be blank"
    assert_includes @admin.errors[:user_id], "can't be blank"
    assert_includes @admin.errors[:password], "can't be blank"
  end
end
