require_relative './client_test_base'

class PulledImageTest < ClientTestBase

  def self.hex_prefix; 'D2E'; end

  test 'C7A',
  'pulled_image? status is true if image has been pulled' do
    pulled_image?('cyberdojofoundation/gcc_assert')
    assert_equal true, status
    assert_equal '', json['output'], json
  end

  test 'F43',
  'pulled_image? status is false if image has not been pulled' do
    pulled_image?('cyberdojofoundation/does_not_exist')
    assert_equal false, status
    assert_equal '', json['output'], json
  end

  test '92F',
  'pulled_image? with illegal image_name returns false' do
    pulled_image?('123/456')
    assert_equal false, status
    assert_equal '', json['output'], json
  end

end
