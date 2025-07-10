require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "markdown should render basic markdown" do
    markdown_text = "# Heading\n\nThis is **bold** text."
    result = markdown(markdown_text)
    
    assert_includes result, "<h1>Heading</h1>"
    assert_includes result, "<strong>bold</strong>"
  end

  test "markdown should handle empty content" do
    assert_equal "", markdown("")
    assert_equal "", markdown(nil)
  end

  test "markdown should render code blocks" do
    markdown_text = "```ruby\ncode here\n```"
    result = markdown(markdown_text)
    
    # With syntax highlighting, the output should contain proper HTML structure
    assert_includes result, '<div class="highlight">'
    assert_includes result, "<pre><code>"
    assert_includes result, "<span class=\"n\">code</span>"
    assert_includes result, "<span class=\"n\">here</span>"
  end

  test "markdown should render links with target blank" do
    markdown_text = "[Link](https://example.com)"
    result = markdown(markdown_text)
    
    assert_includes result, 'target="_blank"'
    assert_includes result, 'href="https://example.com"'
  end

  test "format_date_with_weekday should format date correctly" do
    date = Date.new(2025, 1, 9) # Thursday
    result = format_date_with_weekday(date)
    
    assert_equal "2025年01月09日（木）", result
  end

  test "format_date_with_weekday should handle different weekdays" do
    dates_and_weekdays = [
      [Date.new(2025, 1, 5), "日"],  # Sunday
      [Date.new(2025, 1, 6), "月"],  # Monday
      [Date.new(2025, 1, 7), "火"],  # Tuesday
      [Date.new(2025, 1, 8), "水"],  # Wednesday
      [Date.new(2025, 1, 9), "木"],  # Thursday
      [Date.new(2025, 1, 10), "金"], # Friday
      [Date.new(2025, 1, 11), "土"]  # Saturday
    ]
    
    dates_and_weekdays.each do |date, weekday|
      result = format_date_with_weekday(date)
      assert_includes result, "（#{weekday}）"
    end
  end
end