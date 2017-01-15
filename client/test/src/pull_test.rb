require_relative 'test_base'

class PullTest < TestBase

  def self.hex_prefix; '4CD0A'; end

  test '5EC',
  'pulled?(valid but unpulled image_name) is false' do
    refute pulled?({ image_name: 'lazybox' })
  end

  # - - - - - - - - - - - - - - - - - - - - -

  test 'A82',
  'pull(valid image_name) succeeds' do
    pull({ image_name: 'busybox' })
  end

end
