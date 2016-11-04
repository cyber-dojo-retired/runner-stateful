require_relative './client_test_base'

class OldKataTest < ClientTestBase

  def self.hex_prefix; '3DCDF'; end

  test '586',
  "old_kata(kata_id) succeeds example" do
    new_kata
    assert_equal success, status
    old_kata
    assert_equal success, status
    assert_equal '', stdout, json.to_s
    assert_equal '', stderr, json.to_s
  end

end
