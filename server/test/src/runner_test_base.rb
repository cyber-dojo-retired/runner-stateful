require 'json'
require_relative '../hex_mini_test'
require_relative './../../src/docker_runner'
require_relative './../../src/externals'

class RunnerTestBase < HexMiniTest

  def kata_setup
    @image_name = image_for_test
    new_kata
    new_avatar
  end

  def kata_teardown
    old_avatar
    old_kata
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  include Externals
  def runner; @runner ||= DockerRunner.new(self); end

  def pulled?; runner.pulled?(@image_name); end
  def pull; runner.pull(@image_name); end

  def new_kata; runner.new_kata(@image_name, kata_id); end
  def old_kata; runner.old_kata(kata_id); end

  def new_avatar; runner.new_avatar(@image_name, kata_id, avatar_name, files); end
  def old_avatar; runner.old_avatar(kata_id, avatar_name); end

  def runner_run(changed_files, max_seconds = 10, deleted_filenames = [])
    # don't call this run() as it clashes with MiniTest
    args = []
    args << @image_name
    args << kata_id
    args << avatar_name
    args << deleted_filenames
    args << changed_files
    args << max_seconds
    @sss = runner.run(*args)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def sss; @sss; end

  def stdout; sss[0]; end
  def stderr; sss[1]; end
  def status; sss[2]; end

  def assert_stdout(expected); assert_equal expected, stdout, sss; end
  def assert_stderr(expected); assert_equal expected, stderr, sss; end
  def assert_status(expected); assert_equal expected, status, sss; end

  def assert_stdout_include(text); assert stdout.include?(text), sss; end
  def assert_stderr_include(text); assert stderr.include?(text), sss; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_cyber_dojo_sh_no_stderr(script)
    assert_run_succeeds_no_stderr({ 'cyber-dojo.sh' => script })
  end

  def assert_run_succeeds_no_stderr(*args)
    stdout,stderr = assert_run_succeeds(*args)
    assert_equal '', stderr, stdout
    stdout
  end

  def assert_run_succeeds(*args)
    stdout,stderr,status = runner_run(*args)
    assert_equal success, status, [stdout,stderr]
    [stdout,stderr]
  end

  def assert_run_times_out(*args)
    stdout,stderr,status = runner_run(*args)
    assert_equal timed_out, status, [stdout,stderr]
    [stdout,stderr]
  end

  def assert_exec(cmd)
    stdout,stderr,status = exec(cmd)
    assert_equal success, status, [stdout,stderr]
    [stdout,stderr]
  end

  def exec(cmd, logging = true)
    shell.exec(cmd, logging)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def image_for_test
    rows = {
      '[C#,NUnit]'      => 'csharp_nunit',
      '[C#,Moq]'        => 'csharp_moq',
      '[gcc,assert]'    => 'gcc_assert',
      '[Java,Cucumber]' => 'java_cucumber_pico',
      '[Alpine]'        => 'gcc_assert',
      '[Ubuntu]'        => 'clangpp_assert'
    }
    row = rows.detect { |key,name| test_name.start_with? key }
    fail 'cannot find image_name from test_name' if row.nil?
    'cyberdojofoundation/' + row[1]
  end

  def files(language_dir = language_dir_from_image_name)
    @files ||= load_files(language_dir)
  end

  def language_dir_from_image_name
    fail '@image_name.nil? so cannot set language_dir' if @image_name.nil?
    @image_name.split('/')[1]
  end

  def load_files(language_dir)
    dir = "/app/start_files/#{language_dir}"
    json = JSON.parse(IO.read("#{dir}/manifest.json"))
    @image_name = json['image_name']
    Hash[json['visible_filenames'].collect { |filename|
      [filename, IO.read("#{dir}/#{filename}")]
    }]
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def user; runner.user; end
  def group; runner.group; end
  def sandbox; runner.sandbox; end

  def success; runner.success; end
  def timed_out; runner.timed_out; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def kata_id; test_id + '0' * (10-test_id.length); end
  def avatar_name; 'salmon'; end

end
