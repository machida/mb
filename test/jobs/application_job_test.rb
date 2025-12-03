require "test_helper"

class ApplicationJobTest < ActiveSupport::TestCase
  test "should inherit from ActiveJob::Base" do
    assert ApplicationJob < ActiveJob::Base
  end

  test "should be inherited by job classes" do
    assert ApplicationJob.is_a?(Class)
    assert_equal ActiveJob::Base, ApplicationJob.superclass
  end
end
