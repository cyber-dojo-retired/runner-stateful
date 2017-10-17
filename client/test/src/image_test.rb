require_relative 'test_base'

class ImageTest < TestBase

  def self.hex_prefix
    '4CD0A7F'
  end

  # - - - - - - - - - - - - - - - - - - - - -
  # image_pulled?
  # - - - - - - - - - - - - - - - - - - - - -

  test '5EC',
  'image_pulled?(valid but unpulled image_name) is false' do
    assert_equal false, image_pulled?({image_name:'lazybox'})
  end

  # - - - - - - - - - - - - - - - - - - - - -

  test 'B22',
  'image_pulled?(valid and pulled image_name) is true' do
    image_pull({image_name:'busybox'})
    assert_equal true, image_pulled?({image_name:'busybox'})
  end

  # - - - - - - - - - - - - - - - - - - - - -

  test 'D71',
  'image_pulled?(invalid_image name) raises' do
    error = assert_raises(StandardError) {
      image_pulled?({image_name:'_cantStartWithSeparator'})
    }
    expected = 'RunnerService:image_pulled?:image_name:invalid'
    assert_equal expected, error.message
  end

  # - - - - - - - - - - - - - - - - - - - - -
  # pull
  # - - - - - - - - - - - - - - - - - - - - -

  test 'A82',
  'image_pull(valid and existing image_name) returns true' do
    assert_equal true, image_pull({image_name:"#{cdf}/gcc_assert"})
  end

  # - - - - - - - - - - - - - - - - - - - - -

  test '667',
  'image_pull(valid non-existing image_name) returns false' do
    assert_equal false, image_pull({image_name:"#{cdf}/lazybox"})
  end

  # - - - - - - - - - - - - - - - - - - - - -

  test '1A7',
  'image_pull(invalid_image name) raises' do
    error = assert_raises(StandardError) {
      image_pull({image_name:'_cantStartWithSeparator'})
    }
    expected = 'RunnerService:image_pull:image_name:invalid'
    assert_equal expected, error.message
  end

end
