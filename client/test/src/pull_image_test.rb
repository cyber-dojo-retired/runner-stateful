require_relative './client_test_base'

class PullImageTest < ClientTestBase

  def self.hex_prefix; '4FA'; end

  test 'F30',
  'pull_image with illegal image_name returns error' do
    illegal_name = '123/456'
    pull_image(illegal_name)
    assert_equal 'error', status
    assert_equal '', stdout
    assert_equal [
        "status(1)",
        "stdout(Using default tag: latest",
        "Pulling repository docker.io/#{illegal_name})",
        "stderr(Error: image #{illegal_name}:latest not found)"
    ].join("\n"), stderr
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  test '4CE',
  'pull_image with legal name succeeds' do
    pull_image('cyberdojofoundation/gcc_assert')
    assert_equal success, status
    assert stdout.include?('Pulling from cyberdojofoundation/gcc_assert'), json
    assert_equal '', stderr
  end

end
