require_relative '../hex_mini_test'
require_relative '../../src/externals'
require_relative '../../src/runner'
require 'json'

class TestBase < HexMiniTest

  def kata_setup
    set_image_name image_for_test
    new_kata
    new_avatar
  end

  def kata_teardown
    old_avatar
    old_kata
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def new_runner(image_name, kata_id)
    Object.const_get(runner_class_name).new(self, image_name, kata_id)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def image_pulled?
    runner.image_pulled?
  end

  def image_pull
    runner.image_pull
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def kata_exists?
    runner.kata_exists?
  end

  def new_kata
    runner.new_kata
  end

  def old_kata
    runner.old_kata
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def avatar_exists?(avatar_name = 'salmon')
    runner.avatar_exists?(avatar_name)
  end

  def new_avatar(avatar_name = 'salmon', the_files = files)
    runner.new_avatar(avatar_name, the_files)
  end

  def old_avatar(avatar_name = 'salmon')
    runner.old_avatar(avatar_name)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def sss_run(named_args = {})
    # don't name this run() as it clashes with MiniTest
    args = []
    args << defaulted_arg(named_args, :avatar_name, 'salmon')
    args << defaulted_arg(named_args, :deleted_filenames, [])
    args << defaulted_arg(named_args, :changed_files, files)
    args << defaulted_arg(named_args, :max_seconds, 10)
    @sss = runner.run(*args)
    [stdout,stderr,status]
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def defaulted_arg(named_args, arg_name, arg_default)
    named_args.key?(arg_name) ? named_args[arg_name] : arg_default
  end

  def set_image_name(image_name); @image_name = image_name; end
  def image_name; @image_name; end
  def kata_id; hex_test_id + '0' * (10-hex_test_id.length); end
  def avatar_name; 'salmon'; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  include Externals
  include Runner

  def sss; @sss; end

  def stdout; sss[:stdout]; end
  def stderr; sss[:stderr]; end
  def status; sss[:status]; end

  def assert_stdout(expected); assert_equal expected, stdout, sss; end
  def assert_stderr(expected); assert_equal expected, stderr, sss; end
  def assert_status(expected); assert_equal expected, status, sss; end

  def assert_stdout_include(text); assert stdout.include?(text), sss; end
  def assert_stderr_include(text); assert stderr.include?(text), sss; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_cyber_dojo_sh(script, named_args={})
    named_args[:changed_files] = { 'cyber-dojo.sh' => script }
    assert_run_succeeds(named_args)
  end

  def assert_run_succeeds(named_args)
    stdout,stderr,status = sss_run(named_args)
    assert_equal success, status, [stdout,stderr]
    assert_equal '', stderr, stdout
    stdout
  end

  def assert_run_times_out(named_args)
    stdout,stderr,status = sss_run(named_args)
    assert_equal timed_out, status, [stdout,stderr]
    [stdout,stderr]
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
    row = rows.detect { |key,_| hex_test_name.start_with? key }
    fail 'cannot find image_name from hex_test_name' if row.nil?
    'cyberdojofoundation/' + row[1]
  end

  def files(language_dir = language_dir_from_image_name)
    @files ||= load_files(language_dir)
  end

  def language_dir_from_image_name
    fail 'image_name.nil? so cannot set language_dir' if image_name.nil?
    image_name.split('/')[1]
  end

  def load_files(language_dir)
    dir = "/app/start_files/#{language_dir}"
    json = JSON.parse(IO.read("#{dir}/manifest.json"))
    set_image_name json['image_name']
    Hash[json['visible_filenames'].collect { |filename|
      [filename, IO.read("#{dir}/#{filename}")]
    }]
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def user_id(name = 'salmon')
    runner.user_id(name).to_s
  end

  def group
    runner.group
  end

  def gid
    runner.gid
  end

  def sandbox(name = 'salmon')
    runner.avatar_dir(name)
  end

  def success; shell.success; end
  def timed_out; 'timed_out'; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_docker_run(cmd)
    docker_run = [
      'docker run',
      '--rm',
      '--tty',
      image_name,
      "sh -c '#{cmd}'"
    ].join(space = ' ')
    stdout,stderr = assert_exec(docker_run)
    assert_equal '', stderr, stdout
    stdout
  end

  def assert_docker_exec(cmd)
    # child class provides (container_name)
    cid = container_name
    stdout,stderr = assert_exec("docker exec #{cid} sh -c '#{cmd}'")
    assert_equal '', stderr, stdout
    stdout
  end

  def assert_exec(cmd)
    stdout,stderr,status = exec(cmd)
    unless status == success
      fail StandardError.new(cmd)
    end
    [stdout,stderr]
  end

  def exec(cmd, *args)
    shell.exec(cmd, *args)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def with_captured_stdout
    begin
      old_stdout = $stdout
      $stdout = StringIO.new('','w')
      yield
      $stdout.string
    ensure
      $stdout = old_stdout
    end
  end

end
