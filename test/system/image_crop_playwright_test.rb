require "application_playwright_test_case"

class ImageCropPlaywrightTest < ApplicationPlaywrightTestCase
  def setup
    super
    require "vips"
    Vips::Image.black(800, 600, bands: 3).new_from_image([ 50, 150, 220 ]).pngsave(Rails.root.join("tmp/cropper-test.png").to_s)
    login_as_admin
    @page.goto("http://localhost:#{@server_port}/admin/site-settings")
    @page.wait_for_load_state(state: "networkidle")
  end

  test "crop exports the requested aspect ratio and keeps the uploaded preview" do
    open_crop
    dimensions = @page.eval_on_selector("cropper-selection", "async selection => { const canvas = await selection.$toCanvas(); return [canvas.width, canvas.height]; }")
    assert_in_delta 1200.0 / 630, dimensions[0].to_f / dimensions[1], 0.02
    @page.screenshot(path: Rails.root.join("tmp/cropper-desktop.png").to_s)
    @page.click(CROP_CONFIRM)
    @page.wait_for_function("() => document.querySelector('.spec--default-og-image-input').value.startsWith('/uploads/')")
    assert @page.locator(CROP_MODAL).evaluate("element => element.classList.contains('is--hidden')")
    assert_equal 0, @page.locator("cropper-canvas").count
    preview = @page.locator('[data-thumbnail-upload-target="preview"]')
    assert preview.visible?
    @page.wait_for_function("() => document.querySelector('[data-thumbnail-upload-target=preview]').naturalWidth > 0")
    result = preview.evaluate("image => [image.naturalWidth, image.naturalHeight]")
    assert_in_delta 1200.0 / 630, result[0].to_f / result[1], 0.02
  end

  test "cancel on mobile leaves the URL unchanged and permits reopening" do
    @page.set_viewport_size(width: 390, height: 844)
    original = @page.input_value(DEFAULT_OG_IMAGE_INPUT)
    open_crop
    @page.screenshot(path: Rails.root.join("tmp/cropper-mobile.png").to_s)
    @page.click(CROP_CANCEL)
    assert_equal original, @page.input_value(DEFAULT_OG_IMAGE_INPUT)
    assert_equal "", @page.input_value(IMAGE_FILE_INPUT)
    assert_equal 0, @page.locator("cropper-canvas").count
    open_crop
    assert_equal 1, @page.locator("cropper-canvas").count
  end

  private

  def open_crop
    @page.set_input_files(IMAGE_FILE_INPUT, Rails.root.join("tmp/cropper-test.png").to_s)
    @page.wait_for_function("() => document.querySelector('cropper-selection')?.width > 0")
    assert @page.locator(CROP_MODAL).visible?
    inside = @page.evaluate("() => { const s = document.querySelector('cropper-selection').getBoundingClientRect(); const i = document.querySelector('cropper-image').getBoundingClientRect(); const c = document.querySelector('cropper-canvas').getBoundingClientRect(); return {s: s.toJSON(), i: i.toJSON(), c: c.toJSON()}; }")
    assert inside["s"]["right"] <= inside["i"]["right"] + 1, inside.inspect
    assert inside["s"]["bottom"] <= inside["c"]["bottom"] + 1, inside.inspect
  end
end
