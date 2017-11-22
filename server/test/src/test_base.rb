require_relative 'hex_mini_test'
require_relative '../../src/all_avatars_names'
require_relative '../../src/externals'
require_relative '../../src/runner'
require 'json'

class TestBase < HexMiniTest

  def runner
    Runner.new(self, image_name, kata_id)
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

  def kata_new
    runner.kata_new
  end

  def kata_old
    runner.kata_old
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def avatar_exists?(avatar_name = default_avatar_name)
    runner.avatar_exists?(avatar_name)
  end

  def avatar_new(avatar_name = default_avatar_name, the_files = files)
    runner.avatar_new(avatar_name, the_files)
  end

  def avatar_old(avatar_name = default_avatar_name)
    runner.avatar_old(avatar_name)
  end

  def default_avatar_name
    'salmon'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def run_cyber_dojo_sh(named_args = {})
    args = []
    args << defaulted_arg(named_args, :avatar_name, default_avatar_name)
    args << defaulted_arg(named_args, :new_files, {})
    args << defaulted_arg(named_args, :deleted_files, {})
    args << defaulted_arg(named_args, :unchanged_files, {})
    args << defaulted_arg(named_args, :changed_files, {})
    args << defaulted_arg(named_args, :max_seconds, 10)
    @quad = runner.run_cyber_dojo_sh(*args)
    nil
  end

  def defaulted_arg(named_args, arg_name, arg_default)
    named_args.key?(arg_name) ? named_args[arg_name] : arg_default
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def set_image_name(image_name)
    @image_name = image_name
  end

  def image_name
    @image_name ||= manifest['image_name']
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def stdout
    quad[:stdout]
  end

  def stderr
    quad[:stderr]
  end

  def status
    quad[:status]
  end

  def colour
    quad[:colour]
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_stdout(expected)
    assert_equal expected, stdout, quad
  end

  def assert_stderr(expected)
    assert_equal expected, stderr, quad
  end

  def assert_status(expected)
    assert_equal expected, status, quad
  end

  def assert_colour(expected)
    assert_equal expected, colour, quad
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_stderr_include(text)
    assert stderr.include?(text), quad
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_cyber_dojo_sh(script, named_args = {})
    named_args[:changed_files] = { 'cyber-dojo.sh' => script }
    assert_run_succeeds(named_args)
  end

  def assert_run_succeeds(named_args)
    run_cyber_dojo_sh(named_args)
    refute_equal timed_out, colour, quad
    assert_status success
    assert_equal '', stderr
    stdout
  end

  def assert_run_times_out(named_args)
    run_cyber_dojo_sh(named_args)
    assert_colour timed_out
    assert_status 137
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def files
    @files ||= read_files
  end

  def read_files
    Hash[manifest['visible_filenames'].collect { |filename|
      [filename, IO.read("#{starting_files_dir}/#{filename}")]
    }]
  end

  def manifest
    @manifest ||= JSON.parse(IO.read("#{starting_files_dir}/manifest.json"))
  end

  def starting_files_dir
    "/app/test/start_files/#{os}"
  end

  def os
    if hex_test_name.start_with? '[Ubuntu]'
      :Ubuntu
    else # [Alpine] || default
      :Alpine
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def kata_id
    hex_test_id + '0' * (10-hex_test_id.length)
  end

  def avatar_name
    'salmon'
  end

  def user_id(avatar_name = 'salmon')
    40000 + all_avatars_names.index(avatar_name)
  end

  include AllAvatarsNames

  def group
    'cyber-dojo'
  end

  def gid
    5000
  end

  def sandbox(avatar_name = 'salmon')
    "/sandboxes/#{avatar_name}"
  end

  def success
    shell.success
  end

  def timed_out
    'timed_out'
  end

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

  include Externals # eg shell

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

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def cdf
    'cyberdojofoundation'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def ls_cmd
    # Works on Ubuntu and Alpine
    'stat -c "%n %A %u %G %s %y" *'
    # hiker.h  -rw-r--r--  40045  cyber-dojo 136  2016-06-05 07:03:14.539952547
    # |        |           |      |          |    |          |
    # filename permissions user   group      size date       time
    # 0        1           2      3          4    5          6

    # Stat
    #  %z == time of last status change
    #  %y == time of last data modification <<=====
    #  %x == time of last access
    #  %w == time of file birth
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def ls_parse(ls_stdout)
    Hash[ls_stdout.split("\n").collect { |line|
      attr = line.split
      [filename = attr[0], {
        permissions: attr[1],
               user: attr[2].to_i,
              group: attr[3],
               size: attr[4].to_i,
         time_stamp: attr[6],
      }]
    }]
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_equal_atts(filename, permissions, user, group, size, ls_files)
    atts = ls_files[filename]
    refute_nil atts, filename
    assert_equal user,  atts[:user ], { filename => atts }
    assert_equal group, atts[:group], { filename => atts }
    assert_equal size,  atts[:size ], { filename => atts }
    assert_equal permissions, atts[:permissions], { filename => atts }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def in_kata_as(name)
    in_kata {
      as(name) {
        yield
      }
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def in_kata
    kata_new
    yield
  ensure
    kata_old
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def as(name, starting_files = files)
    avatar_new(name, starting_files)
    yield
  ensure
    avatar_old(name)
  end

  private

  def quad
    @quad
  end

end
