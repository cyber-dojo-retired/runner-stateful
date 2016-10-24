
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
    wait_till_container_dead
    remove_volume
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def runner_start
    output, status = runner.start(kata_id, avatar_name)
    assert_equal success, status
    @rm_volume = output.strip
    [ output, status ]
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

  def runner_run(changed_files, max_seconds = 10, delete_filenames = [])
    refute_nil @image_name
    @cid = runner.create_container(@image_name, kata_id, avatar_name)
    runner.delete_deleted_files_from_sandbox(@cid, delete_filenames)
    runner.copy_changed_files_into_sandbox(@cid, changed_files)
    runner.ensure_user_nobody_owns_changed_files(@cid)
    runner.ensure_user_nobody_has_HOME(@cid)
    runner.run(@cid, max_seconds)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def wait_till_container_dead
    # docker_runner.sh does [docker rm --force ${cid}] in a child process.
    # This has a race condition so you need to wait
    # until the container (which has the volume mounted)
    # is 'actually' removed before you can remove the volume.
    if test_creates_container?
      10.times do
        break if container_dead?
        sleep(1)
      end
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def remove_volume
    assert @rm_volume != ''
    _output, status = exec("docker volume rm #{@rm_volume} 2>&1")
    #puts "remove_volume output:#{output}:"
    #puts "remove_volume status:#{status}:"
    assert_equal success, status
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def test_creates_container?
    test_id != '4D87ADBC'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def container_dead?
    refute_nil @cid
    command = "docker inspect --format='{{ .State.Running }}' #{@cid} 2> /dev/null"
    _output, status = exec(command)
    #p "inspect output:#{output}:"
    #p "inspect status:#{status}:"
    status == 1
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def volume_exists?
    output, status = exec('docker volume ls')
    assert_equal success, status
    output.include? volume_name
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def runner; DockerRunner.new(self); end
  def success; 0; end
  def timed_out_and_killed; (timeout = 128) + (kill = 9); end
  def kata_id; test_id; end
  def avatar_name; 'salmon'; end
  def volume_name; 'cyber_dojo_' + kata_id + '_' + avatar_name; end

  include Externals # for shell
  def exec(command); shell.exec(command); end

end

