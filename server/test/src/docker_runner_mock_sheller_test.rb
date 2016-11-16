require_relative './runner_test_base'
require_relative './mock_sheller'

class DockerRunnerMockShellerTest < RunnerTestBase

  def self.hex_prefix; '0D5'; end

  def shell; @shell ||= MockSheller.new(nil); end

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
    shell.mock_exec('docker images', stdout, '', 0)
    runner.logging_off
    refute runner.pulled?(image_name)
    shell.teardown
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '9C3',
  'when image_name is valid, pulled?(image_name) and is false' do
    image_name = 'cdf/ruby_mini_test'
    stdout = [
      'REPOSITORY     TAG    IMAGE ID     CREATED    SIZE',
      'cdf/gcc_assert latest 28683e525ad3 9 days ago 95.97 MB'
    ].join("\n")
    shell.mock_exec('docker images', stdout, '', 0)
    status = runner.pulled?(image_name)
    refute status
    shell.teardown
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'A44',
  'when image_name is valid, pulled?(image_name) is true' do
    image_name = 'cdf/ruby_mini_test'
    stdout = [
      'REPOSITORY     TAG    IMAGE ID     CREATED    SIZE',
      "#{image_name}  latest 28683e525ad3 9 days ago 95.97 MB"
    ].join("\n")
    shell.mock_exec('docker images', stdout, '', 0)
    status = runner.pulled?(image_name)
    assert status
    shell.teardown
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # pull
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'A73',
  'when image_name is invalid, pulled?(image_name) raises DockerRunnerError' do
    image_name = '123/123'
    stdout = [
      'Using default tag: latest',
      "Pulling repository docker.io/#{image_name}"
    ].join("\n")
    stderr = "Error: image #{image_name}:latest not found"
    shell.mock_exec("docker pull #{image_name}", stdout, stderr, 1)
    runner.logging_off
    raised = assert_raises(DockerRunnerError) { runner.pull(image_name) }
    assert_equal 1, raised.status
    assert_equal stdout, raised.stdout
    assert_equal stderr, raised.stderr
    shell.teardown
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '91C',
  'when image_name is valud, pull(image_name) issues unconditional docker-pull' do
    image_name = 'cdf/ruby_mini_test'
    shell.mock_exec("docker pull #{image_name}", '', '', success)
    runner.pull(image_name)
    shell.teardown
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # new_kata
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  # test '933', no network connectivitity
  #stderr = [
  # "Error while pulling image: Get",
  # "https://index.docker.io/v1/repositories/123/123/images:"
  # "dial tcp: lookup index.docker.io on 10.0.2.3:53: no such host"
  # ].join(' ')

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'AED',
  'when image_name is invalid, then new_kata(image_name, kata_id) fails with not-found' do
    bad_image_name = '123/123'
    runner.logging_off
    stdout = [
      'REPOSITORY     TAG    IMAGE ID     CREATED    SIZE',
      'cdf/gcc_assert latest 28683e525ad3 9 days ago 95.97 MB'
    ].join("\n")
    shell.mock_exec('docker images', stdout, '', 0)
    stdout = [
      "Using default tag: latest",
      "Pulling repository docker.io/#{bad_image_name}"
    ].join("\n")
    stderr = "Error: image #{bad_image_name}:latest not found"
    shell.mock_exec("docker pull #{bad_image_name}", stdout, stderr, 1)
    raised = assert_raises(DockerRunnerError) { runner.new_kata(bad_image_name, kata_id) }
    assert_equal 1, raised.status
    assert_equal stdout, raised.stdout
    assert_equal stderr, raised.stderr
    shell.teardown
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
    shell.mock_exec('docker images', stdout, '', 0)
    shell.mock_exec("docker pull #{image_name}", '','',0)
    runner.new_kata(image_name, kata_id)
    shell.teardown
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
    shell.mock_exec('docker images', stdout, '', 0)
    runner.new_kata(image_name, kata_id)
    shell.teardown
  end

end

