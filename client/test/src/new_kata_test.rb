require_relative 'client_test_base'

class NewKataTest < ClientTestBase

  def self.hex_prefix; 'D2E7E'; end

  test 'C7A',
  "when image_name is valid new_kata(kata_id, image_name) succeeds" do
    new_kata
  end

end
