require_relative './client_test_base'

class PulledImageTest < ClientTestBase

  def self.hex_prefix; 'D2E'; end

  test 'C7A',
  'pulled_image? is true if image has been pulled' do
    pulled_image?('cyberdojofoundation/gcc_assert')
    assert_equal true, status
    assert_equal '', stdout, json
  end

  test 'F43',
  'pulled_image? is false if image has not been pulled' do
    pulled_image?('cyberdojofoundation/does_not_exist')
    assert_equal false, status
    assert_equal '', stdout, json
  end

  test '92F',
  'pulled_image? is false with illegal image_name' do
    pulled_image?('123/456')
    assert_equal false, status
    assert_equal '', stdout, json
  end

end
