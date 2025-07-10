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
end
