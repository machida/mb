require "application_system_test_case"

class TailwindBasicTest < ApplicationSystemTestCase
  test "tailwind css is loaded and basic classes work" do
    visit admin_login_path
    
    # Check that the login page has proper Tailwind styling using spec classes
    assert_selector ".spec-login-form", minimum: 1
    assert_selector ".spec-login-title", minimum: 1
    assert_selector ".spec-email-input", minimum: 1
    assert_selector ".spec-password-input", minimum: 1
    assert_selector ".spec-login-button", minimum: 1
    
    # Check that Tailwind classes are applied to these elements
    assert_selector ".spec-login-form.max-w-md", minimum: 1
    assert_selector ".spec-login-form.mx-auto", minimum: 1
    assert_selector ".spec-login-form.bg-white", minimum: 1
    assert_selector ".spec-login-form.rounded-lg", minimum: 1
    assert_selector ".spec-login-form.shadow-md", minimum: 1
    
    # Check form styling
    assert_selector ".spec-email-input.border", minimum: 1
    assert_selector ".spec-email-input.rounded-md", minimum: 1
    assert_selector ".spec-email-input.w-full", minimum: 1
    assert_selector ".spec-email-input.px-3", minimum: 1
    assert_selector ".spec-email-input.py-2", minimum: 1
    
    # Check button styling
    assert_selector ".spec-login-button.bg-blue-500", minimum: 1
    assert_selector ".spec-login-button.text-white", minimum: 1
    assert_selector ".spec-login-button.w-full", minimum: 1
    
    # Check text classes
    assert_selector ".spec-login-title.text-2xl", minimum: 1
    assert_selector ".spec-login-title.font-bold", minimum: 1
    assert_selector ".spec-login-title.text-center", minimum: 1
  end

  test "tailwind responsive and utility classes work" do
    visit root_path
    
    # Check that basic container and layout classes are applied using spec classes
    assert_selector ".spec-articles-container", minimum: 1
    assert_selector ".spec-main-title", minimum: 1
    
    # Check that Tailwind classes are applied to these elements
    assert_selector ".spec-articles-container.max-w-4xl", minimum: 1
    assert_selector ".spec-articles-container.mx-auto", minimum: 1
    
    # Check flex classes
    assert_selector ".flex", minimum: 1
    assert_selector ".justify-between", minimum: 1
    assert_selector ".items-center", minimum: 1
    
    # Check spacing classes
    assert_selector ".mb-8", minimum: 1
    assert_selector ".space-y-6", minimum: 1
    
    # Check text classes
    assert_selector ".spec-main-title.text-3xl", minimum: 1
    assert_selector ".spec-main-title.font-bold", minimum: 1
    
    # Check color classes
    assert_selector ".text-blue-600", minimum: 1
    assert_selector ".text-gray-500", minimum: 1
    
    # Check hover states
    assert_selector ".hover\\:text-blue-800", minimum: 1
  end
end