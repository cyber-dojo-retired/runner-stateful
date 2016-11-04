require 'json'
# coverage must come first
require_relative '../coverage'
require_relative '../hex_mini_test'
require_relative './../../src/docker_runner'
require_relative './../../src/externals'

class RunnerTestBase < HexMiniTest

  def kata_setup
    set_image_for_os
    new_kata
    new_avatar
  end

  def kata_teardown
    old_avatar
    old_kata
  end

  def set_image_for_os
    cdf = 'cyberdojofoundation'
    @image_name = "#{cdf}/csharp_nunit" if test_name.start_with?('[C#,NUnit]')
    @image_name = "#{cdf}/csharp_moq"   if test_name.start_with?('[C#,Moq]')
    @image_name = "#{cdf}/gcc_assert"   if test_name.start_with? '[Alpine]'
    @image_name = "#{cdf}/csharp_nunit" if test_name.start_with? '[Ubuntu]'
    fail "cannot set @image_name from test_name" if @image_name.nil?
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  include Externals
  def runner; @runner ||= DockerRunner.new(self); end

  def new_kata; runner.new_kata(kata_id, @image_name); end
  def old_kata; runner.old_kata(kata_id); end

  def new_avatar; runner.new_avatar(kata_id, avatar_name); end
  def old_avatar; runner.old_avatar(kata_id, avatar_name); end

  def runner_run(changed_files, max_seconds = 10, deleted_filenames = [])
    # don't call this run() as it clashes with MiniTest
    runner.run(@image_name, kata_id, avatar_name, max_seconds, deleted_filenames, changed_files)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_run_completes_no_stderr(*args)
    stdout, stderr = assert_run_completes(*args)
    assert_equal '', stderr
    stdout
  end

  def assert_run_completes(*args)
    stdout, stderr, status = runner_run(*args)
    assert_equal completed, status, [stdout, stderr]
    [stdout, stderr]
  end

  def assert_run_times_out(*args)
    stdout, stderr, status = runner_run(*args)
    assert_equal timed_out, status, [stdout, stderr]
    [stdout, stderr]
  end

  def assert_docker_exec(cid, cmd)
    assert_exec("docker exec #{cid} sh -c '#{cmd}'")
  end

  def assert_exec(cmd)
    stdout, stderr, status = exec(cmd)
    assert_equal success, status, stdout
    [stdout, stderr]
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def files(language_dir)
    @files ||= load_files(language_dir)
  end

  def load_files(language_dir)
    dir = "/app/start_files/#{language_dir}"
    json = JSON.parse(IO.read("#{dir}/manifest.json"))
    @image_name = json['image_name']
    Hash[json['filenames'].collect { |filename|
      [filename, IO.read("#{dir}/#{filename}")]
    }]
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def user; runner.user; end
  def group; runner.group; end
  def sandbox; runner.sandbox; end

  def completed; runner.completed; end
  def timed_out; runner.timed_out; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def avatar_name; 'salmon'; end

  def kata_id;
    assert_equal 8, test_id.length, 'test_id.length'
    test_id + '00'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def exec(cmd, logging = true); shell.exec(cmd, logging); end
  def success; 0; end

end
