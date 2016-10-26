require_relative './null_logger'
require 'json'

module DockerRunnerHelpers

  module_function

  def external_setup
    ENV[env_name('log')] = 'NullLogger'
    assert_equal 'NullLogger', log.class.name
    assert_equal 'ExternalSheller', shell.class.name
  end

  def external_teardown
    wait_till_container_dead unless @cid.nil?
    remove_volume unless @volume.nil?
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def pulled?(image_name)
    runner.pulled?(image_name)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def pull(image_name)
    runner.pull(image_name)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def hello
    output, status = runner.hello(kata_id, avatar_name)
    @volume = volume_name if status == success
    [output, status]
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def goodbye
    output, status = runner.goodbye(kata_id, avatar_name)
    @volume = nil if status == success
    [output, status]
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def files(language_dir = 'gcc_assert')
    @files ||= load_files(language_dir)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def create_container
    refute_nil @image_name
    @cid = runner.create_container(@image_name, kata_id, avatar_name)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def execute(changed_files, max_seconds = 10, deleted_filenames = [])
    # Don't call this run (MiniTest uses that method name)
    cid = create_container
    runner.deleted_files(cid, deleted_filenames)
    runner.changed_files(cid, changed_files)
    runner.setup_home(cid)
    runner.run(cid, max_seconds)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def load_files(language_dir)
    dir = "/app/test/src/language_start_files/#{language_dir}"
    json = JSON.parse(IO.read("#{dir}/manifest.json"))
    @image_name = json['image_name']
    Hash[json['filenames'].collect { |filename|
      [filename, IO.read("#{dir}/#{filename}")]
    }]
  end


  def volume_exists?
    output, _ = assert_exec('docker volume ls')
    output.include? volume_name
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def wait_till_container_dead
    # docker_runner.sh does [docker rm --force ${cid}] in a child process.
    # This has a race so you need to wait for the container (which has the
    # volume mounted) to be removed before you can remove the volume.
    20.times do
      # do the sleep first to keep test coverage at 100%
      sleep(1.0 / 10.0)
      break if container_dead?
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def container_dead?
    refute_nil @cid
    command = "docker inspect --format='{{ .State.Running }}' #{@cid} 2> /dev/null"
    _, status = exec(command)
    # https://gist.github.com/ekristen/11254304
    dead = status == 1
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def remove_volume
    assert_exec("docker volume rm #{volume_name} 2>&1")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def runner; DockerRunner.new(self); end
  def success; 0; end
  def timed_out_and_killed; (timeout = 128) + (kill = 9); end
  def volume_name; 'cyber_dojo_' + kata_id + '_' + avatar_name; end
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
