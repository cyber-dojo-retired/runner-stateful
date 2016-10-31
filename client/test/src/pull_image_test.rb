require_relative './client_test_base'

class PullImageTest < ClientTestBase

  def self.hex_prefix; '4FA'; end

  test '4CE',
  'pull_image status is zero if pull succeeds' do
    pull_image('cyberdojofoundation/gcc_assert')
    assert_equal 0, status
    assert json['output'].include?('Pulling from cyberdojofoundation/gcc_assert'), json
  end

  #test 'F30',
  #'pull_image with illegal image_name returns XXXX' do
  #  pull_image('123/456')
  #  assert_equal 0, status
  #  assert json['output'].include?('Pulling from cyberdojofoundation/gcc_assert'), json
  #end

end
