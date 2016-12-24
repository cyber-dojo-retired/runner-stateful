require_relative './runner_test_base'
require_relative './mock_sheller'

class DockerRunnerMockShellerTest < RunnerTestBase

  def self.hex_prefix; '0D5'; end

  def shell; @shell ||= MockSheller.new(nil); end

  def hex_teardown; shell.teardown; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # pulled?
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'D97',
  'when image_name is invalid, pulled?(image_name) does not raise and result is false' do
    image_name = '123/123'
    stdout = [
      'REPOSITORY     TAG    IMAGE ID     CREATED    SIZE',
      'cdf/gcc_assert latest 28683e525ad3 9 days ago 95.97 MB'
    ].join("\n")
    shell.mock_exec('docker images', stdout, '', success)
    runner.logging_off
    refute runner.pulled?(image_name)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '9C3',
  'when image_name is valid but not in [docker images], pulled?(image_name) is false' do
    image_name = 'cdf/ruby_mini_test'
    stdout = [
      'REPOSITORY     TAG    IMAGE ID     CREATED    SIZE',
      'cdf/gcc_assert latest 28683e525ad3 9 days ago 95.97 MB'
    ].join("\n")
    shell.mock_exec('docker images', stdout, '', success)
    refute runner.pulled?(image_name)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'A44',
  'when image_name is valid and in [docker images], pulled?(image_name) is true' do
    image_name = 'cdf/ruby_mini_test'
    stdout = [
      'REPOSITORY     TAG    IMAGE ID     CREATED    SIZE',
      "#{image_name}  latest 28683e525ad3 9 days ago 95.97 MB"
    ].join("\n")
    shell.mock_exec('docker images', stdout, '', success)
    assert runner.pulled?(image_name)
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
    assert_raises { runner.pull(image_name) }
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
    assert_raises { runner.pull(image_name) }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '91C',
  'when image_name is valid, pull(image_name) issues unconditional docker-pull' do
    image_name = 'cdf/ruby_mini_test'
    shell.mock_exec("docker pull #{image_name}", '', '', success)
    runner.pull(image_name)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # new_kata
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'AED',
  'when image_name is invalid, then new_kata(image_name, kata_id) raises' do
    bad_image_name = '123/123'
    runner.logging_off
    stdout = [
      'REPOSITORY     TAG    IMAGE ID     CREATED    SIZE',
      'cdf/gcc_assert latest 28683e525ad3 9 days ago 95.97 MB'
    ].join("\n")
    shell.mock_exec('docker images', stdout, '', success)
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
  'then new_kata(image_name, kata_id) pulls it' do
    image_name = 'cdf/ruby_mini_test'
    stdout = [
      'REPOSITORY     TAG    IMAGE ID     CREATED    SIZE',
      'cdf/gcc_assert latest 28683e525ad3 9 days ago 95.97 MB'
    ].join("\n")
    shell.mock_exec('docker images', stdout, '', success)
    shell.mock_exec("docker pull #{image_name}", '','',success)
    runner.new_kata(image_name, kata_id)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DFA',
  'when image_name is valid has been pulled',
  'then new_kata(image_name, kata_id) does not pull it' do
    image_name = 'cdf/gcc_assert'
    stdout = [
      'REPOSITORY     TAG    IMAGE ID     CREATED    SIZE',
      "#{image_name}  latest 28683e525ad3 9 days ago 95.97 MB"
    ].join("\n")
    shell.mock_exec('docker images', stdout, '', success)
    runner.new_kata(image_name, kata_id)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # run
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'E92',
  "when there is no volume, run() returns 'no_avatar' error status",
  "enabling the web server to seamlessly transition a pre-runner server's kata",
  'to the new runner' do
    kata_id = '6352F737EA'
    name = 'cyber_dojo_' + kata_id + '_' + avatar_name
    shell.mock_exec("docker volume ls --quiet --filter 'name=#{name}'", '', '', 0)
    args = []
    args << 'cdf/gcc_assert'
    args << kata_id
    args << avatar_name
    args << (deleted_filenames=[])
    args << (changed_files={})
    args << (max_seconds=10)
    error = assert_raises { runner.run(*args) }
    assert_equal 'no_avatar', error.message
  end

end

