require_relative './runner_test_base'

class DockerRunnerPullTest < RunnerTestBase

  def self.hex_prefix; '87FE3'; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'D97',
  'when image_name is invalid pulled? fails' do
    @image_name = '123/123'
    runner.logging_off
    _,_,status = pulled?
    refute status
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'A73',
  'when image_name is invalid then pull fails with not found' do
    @image_name = '123/123'
    runner.logging_off
    raised = assert_raises(DockerRunnerError) { pull }
    refute_equal success, raised.status
    assert_equal [
      "Using default tag: latest",
      "Pulling repository docker.io/#{@image_name}"
    ].join("\n"), raised.stdout
    assert_equal "Error: image #{@image_name}:latest not found", raised.stderr
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  private

  def docker_pulled?
    image_names.include?(@image_name)
  end

  def image_names
    stdout,_ = assert_exec('docker images')
    lines = stdout.split("\n")
    lines.shift # REPOSITORY TAG IMAGE ID CREATED SIZE
    lines.collect { |line| line.split[0] }
  end

end

