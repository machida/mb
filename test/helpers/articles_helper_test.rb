require "test_helper"

class ArticlesHelperTest < ActionView::TestCase
  include ApplicationHelper

  def setup
    Article.destroy_all
    Admin.destroy_all
    SiteSetting.destroy_all
    
    @admin1 = Admin.create!(
      email: "admin1@example.com",
      user_id: "author1",
      password: "password123",
      password_confirmation: "password123"
    )
    
    @admin2 = Admin.create!(
      email: "admin2@example.com", 
      user_id: "author2",
      password: "password123",
      password_confirmation: "password123"
    )
    
    # Default: author display enabled
    SiteSetting.set("author_display_enabled", "true")
  end

  test "show_author_info? should return false when no published articles" do
    # No articles at all
    assert_not show_author_info?
    
    # Only draft articles
    Article.create!(
      title: "Draft Article",
      body: "Draft content",
      author: @admin1.user_id,
      draft: true
    )
    assert_not show_author_info?
  end

  test "show_author_info? should return false when only one author has published articles" do
    Article.create!(
      title: "Published Article 1",
      body: "Content 1",
      author: @admin1.user_id,
      draft: false
    )
    
    Article.create!(
      title: "Published Article 2", 
      body: "Content 2",
      author: @admin1.user_id,
      draft: false
    )
    
    assert_not show_author_info?
  end

  test "show_author_info? should return true when multiple authors have published articles" do
    Article.create!(
      title: "Article by Author 1",
      body: "Content by author 1",
      author: @admin1.user_id,
      draft: false
    )
    
    Article.create!(
      title: "Article by Author 2",
      body: "Content by author 2", 
      author: @admin2.user_id,
      draft: false
    )
    
    assert show_author_info?
  end

  test "show_author_info? should ignore draft articles when counting authors" do
    # Author 1 has published article
    Article.create!(
      title: "Published by Author 1",
      body: "Content",
      author: @admin1.user_id,
      draft: false
    )
    
    # Author 2 has only draft article
    Article.create!(
      title: "Draft by Author 2",
      body: "Content",
      author: @admin2.user_id,
      draft: true
    )
    
    assert_not show_author_info?
  end

  test "show_author_info? should be memoized" do
    # Create test data
    Article.create!(
      title: "Article by Author 1",
      body: "Content",
      author: @admin1.user_id,
      draft: false
    )
    
    Article.create!(
      title: "Article by Author 2",
      body: "Content",
      author: @admin2.user_id,
      draft: false
    )
    
    # First call should set the instance variable
    result1 = show_author_info?
    assert result1
    
    # Second call should use memoized value
    # We can't directly test memoization, but we can verify consistent behavior
    result2 = show_author_info?
    assert_equal result1, result2
  end

  test "show_author_info? should return false when author display is disabled" do
    # Set author display to disabled
    SiteSetting.set("author_display_enabled", "false")
    
    # Create multiple authors with published articles
    Article.create!(
      title: "Article by Author 1",
      body: "Content",
      author: @admin1.user_id,
      draft: false
    )
    
    Article.create!(
      title: "Article by Author 2",
      body: "Content",
      author: @admin2.user_id,
      draft: false
    )
    
    # Should return false despite multiple authors because setting is disabled
    assert_not show_author_info?
  end

  test "show_author_info? should return true when author display is enabled and multiple authors exist" do
    # Set author display to enabled (should be default, but explicit for clarity)
    SiteSetting.set("author_display_enabled", "true")
    
    # Create multiple authors with published articles
    Article.create!(
      title: "Article by Author 1",
      body: "Content",
      author: @admin1.user_id,
      draft: false
    )
    
    Article.create!(
      title: "Article by Author 2",
      body: "Content",
      author: @admin2.user_id,
      draft: false
    )
    
    # Should return true because setting is enabled and multiple authors exist
    assert show_author_info?
  end
end