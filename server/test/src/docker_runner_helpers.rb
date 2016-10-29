require 'json'

module DockerRunnerHelpers

  module_function

  def pulled?(image_name);runner.pulled?(image_name); end
  def pull(image_name); runner.pull(image_name); end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def hello; runner.hello(kata_id, avatar_name); end
  def goodbye; runner.goodbye(kata_id, avatar_name); end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def files(language_dir = 'gcc_assert')
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

  def volume_exists?
    volume_name = 'cyber_dojo_' + kata_id + '_' + avatar_name
    output, _ = assert_exec('docker volume ls')
    output.include? volume_name
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def runner; DockerRunner.new(self); end

  def user; runner.user; end
  def group; runner.group; end
  def sandbox; runner.sandbox; end

  def completed; runner.completed; end
  def timed_out; runner.timed_out; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_run_completes(*args)
    stdout, stderr, status = runner_run(*args)
    assert_equal completed, status, [stdout, stderr]
    [stdout, completed]
  end

  def assert_run_times_out(*args)
    stdout, stderr, status = runner_run(*args)
    assert_equal timed_out, status, [stdout, stderr]
    [stdout, timed_out]
  end

  def runner_run(changed_files, max_seconds = 10, deleted_filenames = [])
    # don't call this run() as it clashes with MiniTest
    runner.run(@image_name, kata_id, avatar_name, max_seconds, deleted_filenames, changed_files)
  end

  def avatar_name; 'salmon'; end

  def kata_id;
    assert_equal 8, test_id.length
    assert test_id =~ /^[0-9A-F]+$/
    test_id + '00'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  include Externals # for shell

  def assert_exec(cmd)
    output, status = exec(cmd)
    assert_equal success, status, output
    [output, status]
  end

  def exec(cmd, logging = true); shell.exec(cmd, logging); end
  def success; 0; end

end
