require_relative 'test_base'
require_relative 'mock_sheller'
require_relative 'spy_logger'

class PullTest < TestBase

  def self.hex_prefix; '0D5'; end

  def shell; @shell ||= MockSheller.new(nil); end
  def hex_teardown; shell.teardown; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # pulled?
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'D97',
  'when image_name is invalid, pulled?(image_name) does not raise and result is false' do
    mock_docker_images_prints_gcc_assert
    refute pulled?({ image_name:'123/123' })
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '9C3',
  'when image_name is valid but not in [docker images], pulled?(image_name) is false' do
    mock_docker_images_prints_gcc_assert
    refute pulled?({ image_name:'cdf/ruby_mini_test' })
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'A44',
  'when image_name is valid and in [docker images], pulled?(image_name) is true' do
    mock_docker_images_prints_gcc_assert
    assert pulled?({ image_name:'cdf/gcc_assert' })
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # pull
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '933',
  'when there is no network connectivitity, pull(image_name) raises' do
    image_name = 'cdf/gcc_assert'
    stdout = [
      'Using default tag: latest',
      "Pulling repository docker.io/#{image_name}"
    ].join("\n")
    stderr = [
      'Error while pulling image: Get',
      "https://index.docker.io/v1/repositories/#{image_name}/images:",
      'dial tcp: lookup index.docker.io on 10.0.2.3:53: no such host'
    ].join(' ')
    shell.mock_exec("docker pull #{image_name}", stdout, stderr, 1)
    @log = SpyLogger.new(self)
    assert_raises { pull({ image_name:image_name }) }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'A73',
  'when image_name is invalid, pulled?(image_name) raises' do
    image_name = '123/123'
    stdout = [
      'Using default tag: latest',
      "Pulling repository docker.io/#{image_name}"
    ].join("\n")
    stderr = "Error: image #{image_name}:latest not found"
    shell.mock_exec("docker pull #{image_name}", stdout, stderr, 1)
    @log = SpyLogger.new(self)
    assert_raises { pull({ image_name:image_name }) }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '91C',
  'when image_name is valid, pull(image_name) issues unconditional docker-pull' do
    mock_docker_pull_cdf_ruby_mini_test
    pull({ image_name:'cdf/ruby_mini_test' })
  end

  private

  def mock_docker_images_prints_gcc_assert
    stdout = 'cdf/gcc_assert'
    cmd = 'docker images --format "{{.Repository}}"'
    shell.mock_exec(cmd, stdout, '', success)
  end

  def mock_docker_pull_cdf_ruby_mini_test
    image_name = 'cdf/ruby_mini_test'
    shell.mock_exec("docker pull #{image_name}", '', '', success)
  end

end

