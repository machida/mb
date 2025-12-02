require "test_helper"

class TailwindConfigTest < ActiveSupport::TestCase
  test "@source paths in application.css point to existing directories" do
    css_file = Rails.root.join("app/assets/tailwind/application.css")
    assert File.exist?(css_file), "Tailwind CSS config file not found"

    content = File.read(css_file)

    # @source ディレクティブを抽出（コメント行を除外）
    source_directives = content.lines
      .reject { |line| line.strip.start_with?("*", "//", "#") }
      .map { |line| line.scan(/@source\s+"([^"]+)"/) }
      .flatten

    assert source_directives.any?, "No @source directives found in #{css_file}"

    source_directives.each do |path|
      # glob パターンからベースディレクトリを抽出
      # 例: "./app/views/**/*.erb" -> "./app/views"
      # 例: "app/components/**/*.rb" -> "app/components"
      base_dir = path.split("/**").first
      base_dir = base_dir.delete_prefix("./")

      full_path = Rails.root.join(base_dir)

      assert Dir.exist?(full_path),
        "@source path '#{path}' points to non-existent directory: #{full_path}\n" \
        "Expected directory to exist at: #{full_path}\n" \
        "Check app/assets/tailwind/application.css and ensure paths are relative to Rails.root"
    end
  end

  test "@source paths do not use incorrect relative paths" do
    css_file = Rails.root.join("app/assets/tailwind/application.css")
    content = File.read(css_file)

    # ../app/ のような間違ったパターンを検出（コメント行を除外）
    invalid_patterns = content.lines
      .reject { |line| line.strip.start_with?("*", "//", "#") }
      .map { |line| line.scan(/@source\s+"(\.\.\/[^"]+)"/) }
      .flatten

    assert_empty invalid_patterns,
      "Found invalid @source paths starting with '../': #{invalid_patterns.join(', ')}\n" \
      "@source paths should be relative to Rails.root, not to the CSS file.\n" \
      "Use './app/views/**/*.erb' or 'app/views/**/*.erb' instead of '../app/views/**/*.erb'"
  end
end
