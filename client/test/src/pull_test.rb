require_relative 'test_base'

class PullerTest < TestBase

  def self.hex_prefix; '4CD0A7F'; end

  test 'D71',
  'pulled?(invalid_image name) raises' do
    error = assert_raises(StandardError) {
      pulled?({image_name:'_cantStartWithSeparator'})
    }
    expected = 'RunnerService:pulled?:image_name:invalid'
    assert_equal expected, error.message
  end

  # - - - - - - - - - - - - - - - - - - - - -

  test '1A7',
  'pull(invalid_image name) raises' do
    error = assert_raises(StandardError) {
      pull({image_name:'_cantStartWithSeparator'})
    }
    expected = 'RunnerService:pull:image_name:invalid'
    assert_equal expected, error.message
  end

  # - - - - - - - - - - - - - - - - - - - - -

  test '5EC',
  'pulled?(valid but unpulled image_name) is false' do
    refute pulled?({image_name:'lazybox'})
  end

  # - - - - - - - - - - - - - - - - - - - - -

  test 'A82',
  'pull(valid image_name) succeeds' do
    assert pull({image_name:'busybox'})
  end

  # - - - - - - - - - - - - - - - - - - - - -

  test '667',
  'pull(valid image_name) raising' do
    error = assert_raises(StandardError) {
      pull({image_name:'non_existent_box'})
    }
    expected = 'RunnerService:pull:command:docker pull non_existent_box'
    assert_equal expected, error.message
  end

end
