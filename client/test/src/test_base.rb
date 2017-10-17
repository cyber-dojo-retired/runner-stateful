require_relative '../hex_mini_test'
require_relative '../../src/runner_service'

class TestBase < HexMiniTest

  def runner
    RunnerService.new
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def image_pulled?(named_args={})
    runner.image_pulled?(*defaulted_args(__method__, named_args))
  end

  def image_pull(named_args={})
    runner.image_pull(*defaulted_args(__method__, named_args))
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def kata_exists?(named_args={})
    runner.kata_exists?(*defaulted_args(__method__, named_args))
  end

  def kata_new(named_args={})
    runner.kata_new(*defaulted_args(__method__, named_args))
  end

  def kata_old(named_args={})
    runner.kata_old(*defaulted_args(__method__, named_args))
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def avatar_exists?(named_args={})
    runner.avatar_exists?(*defaulted_args(__method__, named_args))
  end

  def avatar_new(named_args={})
    runner.avatar_new(*defaulted_args(__method__, named_args))
  end

  def avatar_old(named_args={})
    runner.avatar_old(*defaulted_args(__method__, named_args))
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def run4(named_args={})
    # don't call this run() as it clashes with MiniTest
    @quad = runner.run(*defaulted_args(__method__, named_args))
    nil
  end

  def status
    quad['status']
  end

  def stdout
    quad['stdout']
  end

  def stderr
    quad['stderr']
  end

  def colour
    quad['colour']
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

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

  # - - - - - - - - - - - - - - - - - - - - - - -

  def assert_stdout_include(text)
    assert stdout.include?(text), quad
  end

  def assert_stderr_include(text)
    assert stderr.include?(text), quad
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def defaulted_args(method, named_args)
    args = []

    args << defaulted_arg(named_args, :image_name, default_image_name)
    args << defaulted_arg(named_args, :kata_id, default_kata_id)
    return args if method == :image_pulled?
    return args if method == :image_pull
    return args if method == :kata_exists?
    return args if method == :kata_new
    return args if method == :kata_old

    args << defaulted_arg(named_args, :avatar_name, default_avatar_name)
    return args if method == :avatar_exists?
    return args if method == :avatar_old

    if method == :avatar_new
      args << defaulted_arg(named_args, :starting_files, files)
      return args
    end

    args << defaulted_arg(named_args, :deleted_filenames, [])
    args << defaulted_arg(named_args, :changed_files, files)
    args << defaulted_arg(named_args, :max_seconds, 10)
    return args if method == :run4
  end

  def defaulted_arg(named_args, arg_name, arg_default)
    named_args.key?(arg_name) ? named_args[arg_name] : arg_default
  end

  def default_image_name
    "#{cdf}/gcc_assert"
  end

  def default_kata_id
    test_id + '0' * (10-test_id.length)
  end

  def default_avatar_name
    'salmon'
  end

  def cdf
    'cyberdojofoundation'
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def files
    @files ||= read_files
  end

  def read_files
    filenames =%w( hiker.c hiker.h hiker.tests.c cyber-dojo.sh makefile )
    Hash[filenames.collect { |filename|
      [filename, IO.read("/app/test/start_files/gcc_assert/#{filename}")]
    }]
  end

  def file_sub(name, from, to)
    files[name] = files[name].sub(from, to)
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def timed_out
    'timed_out'
  end

  private

  def quad
    @quad
  end

end
