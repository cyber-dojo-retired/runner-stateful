require_relative './runner_test_base'

class DockerRunnerKataTest < RunnerTestBase

  def self.hex_prefix; 'FB0D4'; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'CC8',
  'when image_name is valid and has not been pulled',
  'then new_kata(kata_id, image_name) pulls it and succeeds' do
    @image_name = 'busybox'
    exec("docker rmi #{@image_name}", logging = false)
    refute docker_pulled?(@image_name)
    _,_,status = new_kata
    begin
      assert status
      assert docker_pulled?(@image_name)
    ensure
      old_kata
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '5E7',
  'when image_name is valid has been pulled',
  'then new_kata(kata_id, image_name) succeeds' do
    @image_name = 'busybox'
    exec("docker pull #{@image_name}", logging = false)
    assert docker_pulled?(@image_name)
    _,_,status = new_kata
    begin
      assert status
      assert docker_pulled?(@image_name)
    ensure
      old_kata
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'AED',
  'when image_name is invalid then new_kata(kata_id, image_name) fails' do
    bad_image_name = '123/123'
    runner.logging_off
    f = assert_raises(DockerRunnerError) { runner.new_kata(kata_id, bad_image_name); }
    assert_equal [
      "Using default tag: latest",
      "Pulling repository docker.io/#{bad_image_name}"
    ].join("\n"), f.stdout
    assert_equal "Error: image #{bad_image_name}:latest not found", f.stderr
    assert_equal 1, f.status
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

