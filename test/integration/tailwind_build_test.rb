require "test_helper"

class TailwindBuildTest < ActiveSupport::TestCase
  def setup
    @output_path = Rails.root.join("app/assets/builds/tailwind.css")
  end

  test "Tailwind CSS builds successfully" do
    # ビルドが成功することを確認
    assert File.exist?(@output_path),
      "Tailwind CSS output file not found at #{@output_path}. " \
      "Run 'bundle exec rails tailwindcss:build' to generate it."

    # 最小限のサイズがあることを確認（空ファイルでない）
    file_size = File.size(@output_path)
    assert file_size > 1000,
      "Tailwind CSS output is too small (#{file_size} bytes). " \
      "This may indicate a build error or missing @source paths."
  end

  test "Tailwind CSS includes classes used in views" do
    skip "Tailwind CSS not built yet" unless File.exist?(@output_path)

    css_content = File.read(@output_path)

    # 実際に使用しているクラスが含まれることを確認
    # プロジェクトで実際に使われている代表的なカスタムクラスをチェック
    expected_classes = [
      ".l--container",
      ".a--button",
      ".text-primary",
      ".a--hero"
    ]

    expected_classes.each do |css_class|
      assert_includes css_content, css_class,
        "Expected class '#{css_class}' not found in compiled CSS.\n" \
        "This may indicate:\n" \
        "1. @source paths in app/assets/tailwind/application.css are incorrect\n" \
        "2. The class is defined in a file not covered by @source patterns\n" \
        "3. Tailwind build cache needs to be cleared (run: bin/rails assets:clobber)"
    end
  end

  test "Tailwind CSS does not include unnecessary bloat" do
    skip "Tailwind CSS not built yet" unless File.exist?(@output_path)

    file_size = File.size(@output_path)

    # ファイルサイズが異常に大きくないことを確認（目安: 500KB以下）
    # プロジェクトが大きくなったら調整してください
    max_size = 500 * 1024 # 500KB

    assert file_size < max_size,
      "Tailwind CSS output is unusually large (#{file_size / 1024}KB). " \
      "Check if @source paths are too broad (e.g., including node_modules)."
  end
end
