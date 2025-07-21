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

  test "ImageUploadComponent can be instantiated" do
    component = ImageUploadComponent.new(
      field_name: :image,
      label: "Test Image",
      upload_url: "/test/upload"
    )
    assert_instance_of ImageUploadComponent, component
  end
  
  test "all view components are autoloaded correctly" do
    # This test ensures app/components is in the autoload path
    assert_nothing_raised do
      PageTitleComponent
      FormErrorsComponent  
      PasswordChangeNoticeComponent
      ArticleNavigationComponent
      ImageUploadComponent
    end
  end
end