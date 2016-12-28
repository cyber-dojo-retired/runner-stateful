require_relative 'client_test_base'

class PullTest < ClientTestBase

  def self.hex_prefix; '4CD0A'; end

  test '5EC',
  'pulled?(valid but unpulled image_name) is false' do
    refute pulled? image_name='lazybox'
  end

  # - - - - - - - - - - - - - - - - - - - - -

  test 'A82',
  'pull(valid image_name) succeeds' do
    pull('busybox')
  end

end
