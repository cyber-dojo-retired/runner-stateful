require_relative './runner_test_base'

class DockerRunnerPullTest < RunnerTestBase

  def self.hex_prefix
    'CFC38'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'A71',
  'pulled?(image_name) is false when image_name has not yet been pulled' do
    _output, status = pulled?('thisdoes/not_exist')
    refute status
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'A4E',
  'pulled?(image_name) is true when image_name has already been pulled' do
    # use image-name of runner itself
    _output, status = pulled?('cyberdojo/runner')
    assert status
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DA5',
  'after pull(image_name) pulled?(image_name) is true' do
    # something small not used in cyber-dojo
    image_name = 'busybox'
    _output, status = pulled?(image_name)
    refute status

    pull(image_name)

    _output, status = pulled?(image_name)
    assert status

    output, status = shell.exec("docker rmi #{image_name}")
    fail "exited(#{status}):#{output}:" unless status == success
  end

end

