require_relative './client_test_base'

class OldKataTest < ClientTestBase

  def self.hex_prefix; '3DCDF'; end

  test '586',
  "old_kata(kata_id) succeeds example" do
    new_kata
    old_kata
  end

end
