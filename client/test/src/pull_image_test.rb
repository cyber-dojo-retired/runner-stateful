require_relative './client_test_base'

class PullImageTest < ClientTestBase

  def self.hex_prefix; '4CD0A'; end

  test 'A82',
  'when image_name is valid pull_image succeeds' do
    pull_image('busybox')
    assert_equal 0, status
  end

end
