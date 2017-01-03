require_relative '../hex_mini_test'
require_relative '../../src/docker_volume_runner'
require_relative '../../src/externals'
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

  def pulled?(named_args = {})
    runner.pulled?(*defaulted_args(__method__, named_args))
  end

  def pull(named_args = {})
    runner.pull(*defaulted_args(__method__, named_args))
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def kata_exists?(named_args = {})
    runner.kata_exists?(*defaulted_args(__method__, named_args))
  end

  def new_kata(named_args = {})
    runner.new_kata(*defaulted_args(__method__, named_args))
  end

  def old_kata(named_args = {})
    runner.old_kata(*defaulted_args(__method__, named_args))
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def avatar_exists?(named_args = {})
    runner.avatar_exists?(*defaulted_args(__method__, named_args))
  end

  def new_avatar(named_args = {})
    runner.new_avatar(*defaulted_args(__method__, named_args))
  end

  def old_avatar(named_args = {})
    runner.old_avatar(*defaulted_args(__method__, named_args))
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def sss_run(named_args = {})
    # don't call this run() as it clashes with MiniTest
    @sss = runner.run(*defaulted_args(__method__, named_args))
    [stdout,stderr,status]
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def defaulted_args(method, named_args)
    method = method.to_s
    args = []

    args << defaulted_arg(named_args, :image_name, image_name)
    return args if ['pulled?','pull'].include?(method)

    default_kata_id = test_id + '0' * (10-test_id.length)
    args << defaulted_arg(named_args, :kata_id, default_kata_id)
    return args if ['kata_exists?','new_kata','old_kata'].include?(method)

    default_avatar_name = 'salmon'
    args << defaulted_arg(named_args, :avatar_name, default_avatar_name)
    return args if ['avatar_exists?','old_avatar'].include?(method)

    if method == 'new_avatar'
      args << defaulted_arg(named_args, :starting_files, files)
      return args
    end

    args << defaulted_arg(named_args, :deleted_filenames, [])
    args << defaulted_arg(named_args, :changed_files, files)
    args << defaulted_arg(named_args, :max_seconds, 10)
    return args if method == 'sss_run'
  end

  def defaulted_arg(named_args, arg_name, arg_default)
    named_args.key?(arg_name) ? named_args[arg_name] : arg_default
  end

  def set_image_name(image_name); @image_name = image_name; end
  def image_name; @image_name; end
  def kata_id; test_id + '0' * (10-test_id.length); end
  def avatar_name; 'salmon'; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  include Externals
  def runner; DockerVolumeRunner.new(self); end

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

  def assert_cyber_dojo_sh_no_stderr(script)
    assert_run_succeeds_no_stderr({
      changed_files: { 'cyber-dojo.sh' => script }
    })
  end

  def assert_run_succeeds_no_stderr(named_args)
    stdout,stderr = assert_run_succeeds(named_args)
    assert_equal '', stderr, stdout
    stdout
  end

  def assert_run_succeeds(named_args)
    stdout,stderr,status = sss_run(named_args)
    assert_equal success, status, [stdout,stderr]
    [stdout,stderr]
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
    row = rows.detect { |key,_| test_name.start_with? key }
    fail 'cannot find image_name from test_name' if row.nil?
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

  def sandbox(name = 'salmon')
    runner.sandbox_path(name)
  end

  def success; shell.success; end
  def timed_out; 'timed_out'; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def invalid_kata_ids
    [
      nil,          # not string
      Object.new,   # not string
      [],           # not string
      '',           # not 10 chars
      '123456789',  # not 10 chars
      '123456789AB',# not 10 chars
      '123456789G'  # not 10 hex-chars
    ]
  end

end
