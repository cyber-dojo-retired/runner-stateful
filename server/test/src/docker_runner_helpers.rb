
require_relative './null_logger'
require 'json'

module DockerRunnerHelpers # mix-in

  module_function

  def external_setup
    ENV[env_name('log')] = 'NullLogger'
    assert_equal 'NullLogger', log.class.name
    assert_equal 'ExternalSheller', shell.class.name
    @rm_volume = ''
  end

  def external_teardown
    # See comments for runner.run(cid, max_seconds)
    wait_till_container_is_dead
    remove_volume
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def runner_start
    output, status = runner.start(kata_id, avatar_name)
    assert_equal success, status
    @rm_volume = output.strip
    [output, status]
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def language_files(language_dir)
    dir = "/app/test/src/language_start_files/#{language_dir}"
    json = JSON.parse(IO.read("#{dir}/manifest.json"))
    @image_name = json['image_name']
    Hash[json['filenames'].collect { |filename|
      [filename, IO.read("#{dir}/#{filename}")]
    }]
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def runner_run(changed_files, max_seconds = 10, deleted_filenames = [])
    refute_nil @image_name
    @cid = runner.create_container(@image_name, kata_id, avatar_name)
    runner.deleted_files(@cid, deleted_filenames)
    runner.changed_files(@cid, changed_files)
    runner.setup_home(@cid)
    runner.run(@cid, max_seconds)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def wait_till_container_is_dead
    # docker_runner.sh does [docker rm --force ${cid}] in a child process.
    # This has a race so you need to wait for the container (which has the
    # volume mounted) to be removed before you can remove the volume.
    unless test_does_not_create_container?
      10.times do
        break if container_dead?
        sleep(1)
      end
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def remove_volume
    assert @rm_volume != ''
    assert_exec("docker volume rm #{@rm_volume} 2>&1")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def test_does_not_create_container?
    test_id == '4D87ADBC'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def container_dead?
    refute_nil @cid
    command = "docker inspect --format='{{ .State.Running }}' #{@cid} 2> /dev/null"
    _, status = exec(command)
    # https://gist.github.com/ekristen/11254304
    status == 1
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def volume_exists?
    output, _ = assert_exec('docker volume ls')
    output.include? volume_name
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def runner; DockerRunner.new(self); end
  def success; 0; end
  def timed_out_and_killed; (timeout = 128) + (kill = 9); end
  def volume_name; 'cyber_dojo_' + kata_id + '_' + avatar_name; end
  def kata_id; test_id; end
  def avatar_name; 'salmon'; end

  include Externals # for shell
  def exec(command); shell.exec(command); end

  def assert_exec(command)
    output, status = exec(command)
    assert_equal success, status
    [output, status]
  end

end
