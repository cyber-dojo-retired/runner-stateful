require_relative './null_logger'
require 'json'

module DockerRunnerHelpers

  module_function

  def pulled?(image_name);runner.pulled?(image_name); end
  def pull(image_name); runner.pull(image_name); end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def hello; runner.hello(kata_id, avatar_name); end
  def goodbye; runner.goodbye(kata_id, avatar_name); end

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

  def execute(changed_files, max_seconds = 10, deleted_filenames = [])
    runner.execute(@image_name, kata_id, avatar_name, max_seconds, deleted_filenames, changed_files)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def volume_exists?
    volume_name = 'cyber_dojo_' + kata_id + '_' + avatar_name
    output, _ = assert_exec('docker volume ls')
    output.include? volume_name
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def runner; DockerRunner.new(self); end
  def success; runner.success; end
  def sandbox; runner.sandbox; end
  def timed_out_and_killed; runner.timed_out_and_killed; end
  def kata_id; test_id; end
  def avatar_name; 'salmon'; end

  def assert_exec(command)
    output, status = exec(command)
    assert_equal success, status, output
    [output, status]
  end

  def assert_execute(*args)
    output, status = execute(*args)
    assert_equal success, status, output
    [output, status]
  end

  def exec(command); shell.exec(command); end

  include Externals # for shell

end
