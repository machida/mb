if ENV["COVERAGE"] || ENV["CI"]
  require "simplecov"
  require "simplecov_json_formatter"

  SimpleCov.start "rails" do
    enable_coverage :branch
    add_filter %w[config/ test/ vendor/]
    track_files "app/**/*.rb"
    formatter SimpleCov::Formatter::MultiFormatter.new([
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::JSONFormatter
    ])
  end
end
