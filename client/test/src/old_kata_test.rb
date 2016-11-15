require_relative './client_test_base'

class OldKataTest < ClientTestBase

  def self.hex_prefix; '3DCDF'; end

  test '586',
  "old_kata(kata_id) succeeds example" do
    new_kata
    assert_success
    old_kata
    assert_success
  end

end
