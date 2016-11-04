require_relative './runner_test_base'

class DockerRunnerPullImageTest < RunnerTestBase

  def self.hex_prefix; '87FE3'; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '91C',
  'when image_name is valid pull_image succeeds' do
    @image_name = 'busybox'
    exec("docker rmi #{@image_name}", logging = false)
    refute docker_pulled?(@image_name)
    _,_,status = pull_image
    begin
      assert status
      assert docker_pulled?(@image_name)
    ensure
      old_kata
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'A73',
  'when image_name is invalid then pull_image fails with not found' do
    @image_name = '123/123'
    runner.logging_off
    f = assert_raises(DockerRunnerError) { pull_image }
    assert_equal 1, f.status
    assert_equal [
      "Using default tag: latest",
      "Pulling repository docker.io/#{@image_name}"
    ].join("\n"), f.stdout
    assert_equal "Error: image #{@image_name}:latest not found", f.stderr
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  private

  def docker_pulled?(image_name)
    image_names.include?(image_name)
  end

  def image_names
    stdout,_,_ = assert_exec('docker images')
    lines = stdout.split("\n")
    lines.shift # REPOSITORY TAG IMAGE ID CREATED SIZE
    lines.collect { |line| line.split[0] }
  end

  def assert_exec(cmd)
    stdout,stderr,status = exec(cmd)
    fail [
      "status(#{status})",
      "stdout(#{stdout.strip})",
      "stderr(#{stderr.strip})"
    ].join("\n") unless status == success
    [stdout, stderr, status]
  end

  def exec(cmd, logging = true); shell.exec(cmd, logging); end

end

