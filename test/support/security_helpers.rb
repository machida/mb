# test/support/security_helpers.rb
module SecurityHelpers
  extend ActiveSupport::Concern
  
  # セキュリティテスト用のヘルパーメソッド
  
  # CSRFトークン関連
  def csrf_token
    session[:_csrf_token] ||= SecureRandom.base64(32)
  end
  
  def assert_csrf_protection(&block)
    assert_raises(ActionController::InvalidAuthenticityToken, &block)
  end
  
  def with_csrf_protection
    original_value = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    yield
  ensure
    ActionController::Base.allow_forgery_protection = original_value
  end
  
  # 認証・認可テスト
  def assert_requires_authentication(path, method: :get, params: {})
    send(method, path, params: params)
    assert_redirected_to admin_login_path
  end
  
  def assert_admin_required(path, method: :get, params: {})
    send(method, path, params: params)
    assert_redirected_to admin_login_path
  end
  
  # セッション関連
  def assert_session_cleared
    assert_nil session[:admin_id]
    assert_nil session[:user_id]
  end
  
  def assert_secure_session
    assert session.dig(:_csrf_token).present?
  end
  
  # パスワード強度テスト
  def assert_password_strength(password, min_length: 8)
    assert password.length >= min_length, "Password too short"
    assert password.match?(/[A-Z]/), "Password must contain uppercase"
    assert password.match?(/[a-z]/), "Password must contain lowercase" 
    assert password.match?(/[0-9]/), "Password must contain number"
  end
  
  def weak_passwords
    %w[
      password
      123456
      admin
      test
      qwerty
      abc123
    ]
  end
  
  def strong_passwords
    %w[
      SecurePass123!
      MyStr0ngP@ssw0rd
      T3st1ngP@ssw0rd!
    ]
  end
  
  # SQLインジェクション対策テスト
  def sql_injection_payloads
    [
      "'; DROP TABLE users; --",
      "' OR '1'='1",
      "1; DELETE FROM admins; --",
      "' UNION SELECT * FROM admins; --"
    ]
  end
  
  def assert_sql_injection_protected(params)
    sql_injection_payloads.each do |payload|
      test_params = params.merge(malicious_input: payload)
      yield(test_params)
      # データが変更されていないことを確認
      assert_no_sql_injection_damage
    end
  end
  
  # XSS対策テスト
  def xss_payloads
    [
      "<script>alert('xss')</script>",
      "javascript:alert('xss')",
      "<img src=x onerror=alert('xss')>",
      "<svg onload=alert('xss')>",
      "';alert('xss');//"
    ]
  end
  
  def assert_xss_protected(response_body)
    xss_payloads.each do |payload|
      assert_not_includes response_body, payload, "XSS payload found in response"
    end
  end
  
  # ファイルアップロードセキュリティ
  def malicious_file_types
    %w[.php .jsp .asp .exe .bat .cmd .sh]
  end
  
  def assert_file_upload_security(upload_endpoint, file_param: :file)
    malicious_file_types.each do |ext|
      malicious_file = create_malicious_file(ext)
      post upload_endpoint, params: { file_param => malicious_file }
      assert_response :unprocessable_entity, "Malicious file #{ext} was accepted"
    end
  end
  
  # レート制限テスト
  def assert_rate_limiting(endpoint, max_requests: 5, time_window: 60)
    (max_requests + 1).times do |i|
      post endpoint
      if i >= max_requests
        assert_response :too_many_requests, "Rate limiting not enforced"
        break
      end
    end
  end
  
  # ヘッダーセキュリティ
  def assert_security_headers(response = nil)
    response ||= @response
    
    # Content Security Policy
    assert response.headers['Content-Security-Policy'].present?
    
    # X-Frame-Options
    assert_equal 'DENY', response.headers['X-Frame-Options']
    
    # X-Content-Type-Options
    assert_equal 'nosniff', response.headers['X-Content-Type-Options']
    
    # X-XSS-Protection
    assert_equal '1; mode=block', response.headers['X-XSS-Protection']
    
    # Strict-Transport-Security (HTTPS環境)
    if Rails.application.config.force_ssl
      assert response.headers['Strict-Transport-Security'].present?
    end
  end
  
  # 機密情報の露出チェック
  def assert_no_sensitive_data_exposure(response_body)
    sensitive_patterns = [
      /password/i,
      /secret/i,
      /api[_-]?key/i,
      /token/i,
      /private[_-]?key/i
    ]
    
    sensitive_patterns.each do |pattern|
      assert_no_match pattern, response_body, "Sensitive data pattern found: #{pattern}"
    end
  end
  
  private
  
  def assert_no_sql_injection_damage
    # 重要なテーブルが削除されていないことを確認
    assert Admin.table_exists?, "Admin table was dropped"
    assert Article.table_exists?, "Article table was dropped"
    assert SiteSetting.table_exists?, "SiteSetting table was dropped"
  end
  
  def create_malicious_file(extension)
    content = case extension
              when '.php'
                '<?php system($_GET["cmd"]); ?>'
              when '.jsp'
                '<% Runtime.getRuntime().exec(request.getParameter("cmd")); %>'
              else
                'malicious content'
              end
    
    Tempfile.new(['malicious', extension]).tap do |file|
      file.write(content)
      file.rewind
    end
  end
end