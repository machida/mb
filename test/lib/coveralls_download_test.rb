require "test_helper"
require "open3"
require "socket"
require "tmpdir"
require "yaml"

class CoverallsDownloadTest < ActiveSupport::TestCase
  test "Coveralls scopes curl settings to its upload step" do
    workflow = YAML.safe_load(Rails.root.join(".github/workflows/ci.yml").read)
    steps = workflow.dig("jobs", "test", "steps")
    upload = steps.find { |step| step["uses"] == "coverallsapp/github-action@v2" }
    assert_equal "${{ github.workspace }}/.github/coveralls-curl", upload.dig("env", "CURL_HOME")
    assert_nil upload["continue-on-error"]
    assert_not_equal false, upload.dig("with", "fail-on-error")
  end

  test "download retries a gateway error and saves only the successful response" do
    with_responses([ 504, 200 ]) do |url, requests|
      Dir.mktmpdir do |directory|
        _, _, status = download(url, directory)
        assert status.success?
        assert_equal 2, requests.size
        assert_equal "valid-checksum\n", File.read(File.join(directory, "coveralls-checksums.txt"))
      end
    end
  end

  test "persistent gateway errors exhaust retries and fail without saving HTML" do
    with_responses([ 504, 504, 504, 504 ]) do |url, requests|
      Dir.mktmpdir do |directory|
        _, stderr, status = download(url, directory)
        assert_equal 22, status.exitstatus
        assert_equal 4, requests.size
        assert_includes stderr, "504"
        path = File.join(directory, "coveralls-checksums.txt")
        assert !File.exist?(path) || File.zero?(path)
      end
    end
  end

  private

  def download(url, directory)
    Open3.capture3(
      { "CURL_HOME" => Rails.root.join(".github/coveralls-curl").to_s, "NO_PROXY" => "127.0.0.1" },
      "curl", "-sLO", url, chdir: directory
    )
  end

  def with_responses(statuses)
    server = TCPServer.new("127.0.0.1", 0)
    requests = []
    thread = Thread.new do
      statuses.each do |status|
        client = server.accept
        requests << client.gets
        while (line = client.gets) && line != "\r\n"
        end
        body = status == 200 ? "valid-checksum\n" : "<html>504 Gateway Time-out</html>"
        client.write("HTTP/1.1 #{status} Response\r\nContent-Length: #{body.bytesize}\r\nConnection: close\r\n\r\n#{body}")
        client.close
      end
    end
    yield "http://127.0.0.1:#{server.addr[1]}/coveralls-checksums.txt", requests
  ensure
    thread&.kill
    thread&.join
    server&.close
  end
end
