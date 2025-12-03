require "test_helper"

class ApplicationRecordTest < ActiveSupport::TestCase
  test "should be an abstract class" do
    assert ApplicationRecord.abstract_class
  end

  test "should be inherited by models" do
    assert Admin < ApplicationRecord
    assert Article < ApplicationRecord
    assert SiteSetting < ApplicationRecord
  end
end
