require_relative './runner_test_base'

class DockerRunnerPullingTest < RunnerTestBase

  def self.hex_prefix; 'CFC38'; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'A71',
  'pulled_image?(image_name) is false when image_name has not yet been pulled' do
    _,_,status = pulled_image?('thisdoes/not_exist')
    refute status
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'A4E',
  'pulled_image?(image_name) is true when image_name has already been pulled' do
    # use image-name of runner itself
    _,_,status = pulled_image?('cyberdojo/runner')
    assert status
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DA5',
  'after pull_image(image_name) pulled_image?(image_name) is true' do
    # something small not used in cyber-dojo
    image_name = 'busybox'
    _,_,status = pulled_image?(image_name)
    refute status
    pull_image(image_name)
    _,_,status = pulled_image?(image_name)
    assert status
    stdout,stderr,status = shell.exec("docker rmi #{image_name}")
    fail "exited(#{status}):#{stdout}:#{stderr}:" unless status == success
  end

end

