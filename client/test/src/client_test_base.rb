require_relative '../hex_mini_test'
require_relative '../../src/runner_service'

class ClientTestBase < HexMiniTest

  def pulled?(name = image_name)
    runner.pulled?(name)
  end

  def pull(name = image_name)
    runner.pull(name)
  end

  def new_kata(name = image_name, id = kata_id)
    runner.new_kata(name, id)
  end

  def old_kata(id = kata_id)
    runner.old_kata(id)
  end

  def new_avatar(iname = image_name, id = kata_id, aname = avatar_name, f = files)
    runner.new_avatar(iname, id, aname, f)
  end

  def old_avatar(id = kata_id, name = avatar_name)
    runner.old_avatar(id, name)
  end

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

  def runner; RunnerService.new; end

  def json; @json; end
  def status; json['status']; end
  def stdout; json['stdout']; end
  def stderr; json['stderr']; end

  def image_name; 'cyberdojofoundation/gcc_assert'; end
  def kata_id; test_id; end
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
