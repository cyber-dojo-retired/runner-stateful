require_relative './client_test_base'

class PullTest < ClientTestBase

  def self.hex_prefix; '4CD0A'; end

  test '5EC',
  'pulled?(valid image_name) false' do
    image_name = 'busybox'
    _,status = pulled? image_name
    refute status
  end

  # - - - - - - - - - - - - - - - - - - - - -

  test 'A82',
  'pull(valid image_name) succeeds' do
    pull('busybox')
    assert_success
  end

end
