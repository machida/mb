require "application_playwright_test_case"

class ClientErrorDiagnosticsPlaywrightTest < ApplicationPlaywrightTestCase
  test "summary parsing and crop failures retain diagnostics and user messages" do
    login_as_admin
    @page.goto("http://localhost:#{@server_port}/admin/articles/new")
    @page.wait_for_load_state(state: "networkidle")

    result = @page.evaluate(<<~JS)
      async () => {
        const { default: SummaryController } = await import('controllers/ai_summary_controller');
        const { default: UploadController } = await import('controllers/thumbnail_upload_controller');
        const originalFetch = window.fetch;
        const originalConsoleError = console.error;
        const diagnostics = [];
        const messages = [];
        const parsingError = new SyntaxError('Invalid JSON response');
        const cropError = new Error('Canvas export failed');
        const button = { disabled: false, innerHTML: 'Generate' };
        const fields = {
          '.spec--title-input': { value: 'Title' },
          '.spec--body-input': { value: 'Body' },
          '.spec--summary-input': { value: '' }
        };
        try {
          console.error = (context, error) => diagnostics.push({
            context, name: error.name, message: error.message, stack: error.stack
          });
          window.fetch = async () => ({ json: async () => { throw parsingError; } });
          await SummaryController.prototype.generate.call({
            element: { closest: () => ({ querySelector: selector => fields[selector] }) },
            urlValue: '/admin/articles/generate_summary',
            showError: message => messages.push(message)
          }, { preventDefault() {}, currentTarget: button });
          await UploadController.prototype.confirmCrop.call({
            cropper: { active: true, toFile: async () => { throw cropError; } },
            selectedFile: new File(['image'], 'image.png'),
            showError: message => messages.push(message)
          });
          return { diagnostics, messages, button };
        } finally {
          window.fetch = originalFetch;
          console.error = originalConsoleError;
        }
      }
    JS

    assert_equal [ "SyntaxError", "Error" ], result["diagnostics"].map { |entry| entry["name"] }
    assert_equal [ "Invalid JSON response", "Canvas export failed" ], result["diagnostics"].map { |entry| entry["message"] }
    result["diagnostics"].each { |entry| assert_includes entry["stack"], entry["message"] }
    assert_equal [ "ネットワークエラーが発生しました", "クロップ処理に失敗しました" ], result["messages"]
    assert_equal false, result["button"]["disabled"]
    assert_equal "Generate", result["button"]["innerHTML"]
  end
end
