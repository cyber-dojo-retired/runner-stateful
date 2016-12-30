require_relative 'test_base'
require_relative 'mock_sheller'

class RunMockShellerTest < TestBase

  def self.hex_prefix; '0D5'; end

  def shell; @shell ||= MockSheller.new(nil); end

  def hex_teardown; shell.teardown; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # pulled?
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'D97',
  'when image_name is invalid, pulled?(image_name) does not raise and result is false' do
    mock_docker_images_prints_gcc_assert
    runner.logging_off
    refute pulled?('123/123')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '9C3',
  'when image_name is valid but not in [docker images], pulled?(image_name) is false' do
    mock_docker_images_prints_gcc_assert
    refute pulled?('cdf/ruby_mini_test')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'A44',
  'when image_name is valid and in [docker images], pulled?(image_name) is true' do
    mock_docker_images_prints_gcc_assert
    assert pulled?('cdf/gcc_assert')
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
    assert_raises { pull(image_name) }
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
    runner.logging_off
    assert_raises { pull(image_name) }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '91C',
  'when image_name is valid, pull(image_name) issues unconditional docker-pull' do
    mock_docker_pull_cdf_ruby_mini_test
    pull('cdf/ruby_mini_test')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # new_kata
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'AED',
  'when image_name is invalid, then new_kata(image_name, kata_id) raises' do
    mock_kata_volume_does_not_exist
    mock_docker_images_prints_gcc_assert

    bad_image_name = '123/123'
    runner.logging_off

    stdout = [
      "Using default tag: latest",
      "Pulling repository docker.io/#{bad_image_name}"
    ].join("\n")
    stderr = "Error: image #{bad_image_name}:latest not found"
    shell.mock_exec("docker pull #{bad_image_name}", stdout, stderr, 1)

    assert_raises { runner.new_kata(bad_image_name, kata_id) }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '36C',
  'when image_name is valid and has not been pulled',
  'then new_kata(image_name, kata_id) pulls it',
  "and creates kata's volume" do
    mock_kata_volume_does_not_exist
    mock_docker_images_prints_gcc_assert
    mock_docker_pull_cdf_ruby_mini_test
    mock_docker_volume_create
    runner.new_kata('cdf/ruby_mini_test', kata_id)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DFA',
  'when image_name is valid has been pulled',
  'then new_kata(image_name, kata_id) does not pull it',
  "and creates kata's volume" do
    mock_kata_volume_does_not_exist
    mock_docker_images_prints_gcc_assert
    mock_docker_volume_create
    runner.new_kata('cdf/gcc_assert', kata_id)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # run
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'E92',
  "when there is no volume, run() returns 'no_kata' error status",
  'enabling the web server to seamlessly transition a pre-runner',
  "server's kata to the new runner" do
    cmd = "docker volume ls --quiet --filter 'name=#{volume_name}'"
    shell.mock_exec(cmd, '', '', success)
    args = []
    args << 'cdf/gcc_assert'
    args << kata_id
    args << avatar_name
    args << (deleted_filenames=[])
    args << (changed_files={})
    args << (max_seconds=10)
    error = assert_raises { runner.run(*args) }
    assert_equal 'no_kata', error.message
  end

  private

  def volume_name
    'cyber_dojo_' + kata_id
  end

  def mock_kata_volume_does_not_exist
    cmd = "docker volume ls --quiet --filter 'name=#{volume_name}'"
    shell.mock_exec(cmd, '', '', success)
  end

  def mock_docker_images_prints_gcc_assert
    stdout = [
      'REPOSITORY     TAG    IMAGE ID     CREATED    SIZE',
      'cdf/gcc_assert latest 28683e525ad3 9 days ago 95.97 MB'
    ].join("\n")
    shell.mock_exec('docker images', stdout, '', success)
  end

  def mock_docker_pull_cdf_ruby_mini_test
    image_name = 'cdf/ruby_mini_test'
    shell.mock_exec("docker pull #{image_name}", '', '', success)
  end

  def mock_docker_volume_create
    cmd = "docker volume create --name #{volume_name}"
    shell.mock_exec(cmd, volume_name, '', success)
  end

end

