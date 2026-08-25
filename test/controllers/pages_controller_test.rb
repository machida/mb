require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get about" do
    get about_path

    assert_response :success
    assert_select "section.l--about-page[aria-labelledby='about-title']"
    assert_select "h1#about-title", "ABOUT"
    assert_select ".l--breadcrumbs__item[aria-current='page']", "ABOUT"
  end
end
