require_relative '../hex_mini_test'
require_relative '../../src/runner_service'

class TestBase < HexMiniTest

  def pulled?(named_args = {})
    runner.pulled?(*defaulted_args(__method__, named_args))
  end

  def pull(named_args = {})
    runner.pull(*defaulted_args(__method__, named_args))
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def new_kata(named_args = {})
    runner.new_kata(*defaulted_args(__method__, named_args))
  end

  def old_kata(named_args = {})
    runner.old_kata(*defaulted_args(__method__, named_args))
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def new_avatar(named_args = {})
    runner.new_avatar(*defaulted_args(__method__, named_args))
  end

  def old_avatar(named_args = {})
    runner.old_avatar(*defaulted_args(__method__, named_args))
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def runner_run(changed_files, max_seconds = 10)
    args = []
    args << image_name
    args << kata_id
    args << avatar_name
    args << deleted_filenames
    args << changed_files
    args << max_seconds
    @json = runner.run(*args)
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def defaulted_args(method, named_args)
    method = method.to_s
    args = []

    args << defaulted_arg(named_args, :image_name, image_name)
    return args if method.include?('pull')

    args << defaulted_arg(named_args, :kata_id, kata_id)
    return args if method.include?('kata')

    args << defaulted_arg(named_args, :avatar_name, avatar_name)
    return args if method == 'old_avatar'

    args << defaulted_arg(named_args, :starting_files, files)
    return args if method == 'new_avatar'

  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def defaulted_arg(named_args, arg_name, arg_default)
    named_args.key?(arg_name) ? named_args[arg_name] : arg_default
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def runner; RunnerService.new; end

  def json; @json; end
  def status; json['status']; end
  def stdout; json['stdout']; end
  def stderr; json['stderr']; end

  def image_name; 'cyberdojofoundation/gcc_assert'; end
  def kata_id; test_id + '0' * (10-test_id.length); end
  def avatar_name; 'salmon'; end
  def deleted_filenames; []; end

  def files; @files ||= read_files; end
  def read_files
    filenames =%w( hiker.c hiker.h hiker.tests.c cyber-dojo.sh makefile )
    Hash[filenames.collect { |filename|
      [filename, IO.read("/app/start_files/gcc_assert/#{filename}")]
    }]
  end

  def file_sub(name, from, to)
    files[name] = files[name].sub(from, to)
  end

  def success; 0; end
  def timed_out; 'timed_out'; end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def assert_success; assert_equal success, status, json.to_s; end
  def refute_success; refute_equal success, status, json.to_s; end

  def assert_timed_out; assert_equal timed_out, status, json.to_s; end

  def assert_stdout(expected); assert_equal expected, stdout, json.to_s; end
  def assert_stderr(expected); assert_equal expected, stderr, json.to_s; end
  def assert_status(expected); assert_equal expected, status, json.to_s; end

end
