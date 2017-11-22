require_relative 'test_base'

class CustomAssertTest < TestBase

  def self.hex_prefix
    '7D428'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '248',
  '[Alpine] good assert_exec does not raise' do
    stdout,stderr = assert_exec 'echo Hello'
    assert_equal 'Hello', stdout.strip
    assert_equal '', stderr
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '249',
  '[Alpine] bad assert_exec raises' do
    @log = LoggerSpy.new(self)
    error = assert_raises { assert_exec 'xxxx' }
    assert_equal 'No such file or directory - xxxx', error.message
    assert_equal [
      line,
      'COMMAND:xxxx',
      'RAISED-CLASS:Errno::ENOENT',
      'RAISED-TO_S:No such file or directory - xxxx'
    ], @log.spied
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '433',
  '[Alpine] good assert_docker_exec does not raise' do
    cmd = "docker run -it --detach --name=#{container_name} #{image_name} sh"
    stdout,_ = assert_exec(cmd)
    cid = stdout.strip
    begin
      stdout = assert_docker_exec 'whoami'
      assert_equal 'root', stdout.strip
    ensure
      cmd = "docker rm --force --volumes #{cid}"
      assert_exec(cmd)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '434',
  '[Alpine] bad assert_docker_exec raises' do
    @log = LoggerSpy.new(self)
    cmd = "docker run -it --detach --name=#{container_name} #{image_name} sh"
    stdout,_ = assert_exec(cmd)
    cid = stdout.strip
    begin
      error = assert_raises { assert_docker_exec 'xxxx' }
      expected = "docker exec #{container_name} sh -c 'xxxx'"
      assert_equal expected, error.message
      assert_equal [
        line,
        "COMMAND:#{expected}",
        'STATUS:127',
        'STDOUT:',
        'STDERR:sh: xxxx: not found' + "\n",
      ], @log.spied
    ensure
      cmd = "docker rm --force --volumes #{cid}"
      assert_exec(cmd)
    end
  end

  private

  def container_name
    'cyber_dojo_kata_container_runner_' + kata_id
  end

  def line
    '-' * 40
  end

end