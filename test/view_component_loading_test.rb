require "test_helper"

class ViewComponentLoadingTest < ActiveSupport::TestCase
  test "PageTitleComponent can be instantiated" do
    component = PageTitleComponent.new(title: "Test Title")
    assert_instance_of PageTitleComponent, component
  end
  
  test "FormErrorsComponent can be instantiated" do
    admin = Admin.new
    component = FormErrorsComponent.new(object: admin)
    assert_instance_of FormErrorsComponent, component
  end
  
  test "PasswordChangeNoticeComponent can be instantiated" do
    component = PasswordChangeNoticeComponent.new
    assert_instance_of PasswordChangeNoticeComponent, component
  end
  
  test "ArticleNavigationComponent can be instantiated" do
    component = ArticleNavigationComponent.new
    assert_instance_of ArticleNavigationComponent, component
  end
  
  test "all view components are autoloaded correctly" do
    # This test ensures app/components is in the autoload path
    assert_nothing_raised do
      PageTitleComponent
      FormErrorsComponent  
      PasswordChangeNoticeComponent
      ArticleNavigationComponent
    end
  end
end