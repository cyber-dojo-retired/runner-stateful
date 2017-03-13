require_relative 'test_base'

class PullerTest < TestBase

  def self.hex_prefix; '4CD0A7F'; end

  # - - - - - - - - - - - - - - - - - - - - -
  # pulled?
  # - - - - - - - - - - - - - - - - - - - - -

  test '5EC',
  'pulled?(valid but unpulled image_name) is false' do
    assert_equal false, pulled?({image_name:'lazybox'})
  end

  # - - - - - - - - - - - - - - - - - - - - -

  test 'B22',
  'pulled?(valid and pulled image_name) is true' do
    pull({image_name:'busybox'})
    assert_equal true, pulled?({image_name:'busybox'})
  end

  # - - - - - - - - - - - - - - - - - - - - -

  test 'D71',
  'pulled?(invalid_image name) raises' do
    error = assert_raises(StandardError) {
      pulled?({image_name:'_cantStartWithSeparator'})
    }
    expected = 'RunnerService:pulled?:image_name:invalid'
    assert_equal expected, error.message
  end

  # - - - - - - - - - - - - - - - - - - - - -
  # pull
  # - - - - - - - - - - - - - - - - - - - - -

  test 'A82',
  'pull(valid and existing image_name) succeeds and returns true' do
    assert_equal true, pull({image_name:'busybox'})
  end

  # - - - - - - - - - - - - - - - - - - - - -

  test '667',
  'pull(valid non-existing image_name) raises' do
    error = assert_raises(StandardError) {
      pull({image_name:'non_existent_box'})
    }
    expected = 'RunnerService:pull:command:docker pull non_existent_box'
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

end
