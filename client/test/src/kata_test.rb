require_relative 'test_base'

class KataTest < TestBase

  def self.hex_prefix; 'D2E7E'; end

  test 'C7A',
  "when image_name is valid new_kata(image_name, kata_id) succeeds" do
    new_kata
    old_kata
  end

end
