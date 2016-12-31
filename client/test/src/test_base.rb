require_relative '../hex_mini_test'
require_relative '../../src/runner_service'

class TestBase < HexMiniTest

  def pulled?(args_hash = {})
    args_hash[:image_name] = image_name unless args_hash.key? :image_name
    runner.pulled?(args_hash[:image_name])
  end

  def pull(args_hash = {})
    args_hash[:image_name] = image_name unless args_hash.key? :image_name
    runner.pull(args_hash[:image_name])
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def new_kata(args_hash = {})
    args_hash[:image_name] = image_name unless args_hash.key? :image_name
    args_hash[:kata_id] = kata_id unless args_hash.key? :kata_id
    args = []
    args << args_hash[:image_name]
    args << args_hash[:kata_id]
    runner.new_kata(*args)
  end

  def old_kata(args_hash = {})
    args_hash[:image_name] = image_name unless args_hash.key? :image_name
    args_hash[:kata_id] = kata_id unless args_hash.key? :kata_id
    args = []
    args << args_hash[:image_name]
    args << args_hash[:kata_id]
    runner.old_kata(*args)
  end

  # - - - - - - - - - - - - - - - - - - - - - - -

  def new_avatar(args_hash = {})
    args_hash[:image_name] = image_name unless args_hash.key? :image_name
    args_hash[:kata_id] = kata_id unless args_hash.key? :kata_id
    args_hash[:avatar_name] = avatar_name unless args_hash.key? :avatar_name
    args_hash[:starting_files] = files unless args_hash.key? :starting_files
    args = []
    args << args_hash[:image_name]
    args << args_hash[:kata_id]
    args << args_hash[:avatar_name]
    args << args_hash[:starting_files]
    runner.new_avatar(*args)
  end

  def old_avatar(args_hash = {})
    args_hash[:image_name] = image_name unless args_hash.key? :image_name
    args_hash[:kata_id] = kata_id unless args_hash.key? :kata_id
    args_hash[:avatar_name] = avatar_name unless args_hash.key? :avatar_name
    args = []
    args << args_hash[:image_name]
    args << args_hash[:kata_id]
    args << args_hash[:avatar_name]
    runner.old_avatar(*args)
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
