require "test_helper"

class Admin::ArticlesHelperTest < ActionView::TestCase
  include ApplicationHelper

  test "format_date_with_weekday should format date correctly" do
    date = Time.zone.parse("2025-01-15 10:30:00")
    
    result = format_date_with_weekday(date)
    
    assert_match /2025年\d{2}月\d{2}日/, result
    assert_match /（.+）/, result  # Should contain weekday in parentheses
  end

  test "format_date_with_weekday should handle different dates" do
    # Test different dates to ensure consistent formatting
    dates = [
      Time.zone.parse("2025-12-31 23:59:59"),
      Time.zone.parse("2025-01-01 00:00:00"),
      Time.zone.parse("2025-06-15 12:00:00")
    ]
    
    dates.each do |date|
      result = format_date_with_weekday(date)
      assert_match /\d{4}年\d{2}月\d{2}日/, result
      assert_match /（.+）/, result
    end
  end

  test "format_date_with_weekday should be consistent" do
    date = Time.zone.parse("2025-01-15 10:30:00")
    
    result1 = format_date_with_weekday(date)
    result2 = format_date_with_weekday(date)
    
    assert_equal result1, result2
  end
end