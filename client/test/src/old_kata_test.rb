require_relative './client_test_base'

class OldKataTest < ClientTestBase

  def self.hex_prefix; '3DCDF'; end

  test '586',
  "when image_name is valid old_kata(kata_id, image_name)'s status is zero" do
    new_kata
    old_kata
    assert_equal 0, status
    assert_equal '', stdout, json.to_s
    assert_equal '', stderr, json.to_s
  end

end
