# require coverage before any files to be covered.
require_relative './../coverage'
require_relative './../hex_mini_test'
require_relative './../../src/runner_service_adapter'

class ClientTestBase < HexMiniTest

  def new_kata(id = kata_id, name = image_name)
    @json = runner.new_kata(id, name)
  end

  def old_kata(id = kata_id, name = image_name)
    @json = runner.old_kata(id, name)
  end

  def new_avatar(id = kata_id, name = avatar_name)
    @json = runner.new_avatar(id, name)
  end

  def old_avatar(id = kata_id, name = avatar_name)
    @json = runner.old_avatar(id, name)
  end

  def runner_run(changed_files, max_seconds = 10)
    @json = runner.run(image_name, kata_id, avatar_name, max_seconds, deleted_filenames, changed_files)
  end

  def runner
    RunnerServiceAdapter.new
  end

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

  def completed;   0; end
  def timed_out; 128; end

end
