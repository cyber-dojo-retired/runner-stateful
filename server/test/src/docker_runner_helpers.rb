
require_relative './null_logger'
require 'json'

# TODO?
# expose container's cid and ensure [docker rm #{cid}]
# happens in external_teardown

module DockerRunnerHelpers # mix-in

  module_function

  def external_setup
    assert_equal 'ExternalSheller', shell.class.name
    ENV[env_name('log')] = 'NullLogger'
    @rm_volume = ''
  end

  def external_teardown
    remove_volume(@rm_volume) unless @rm_volume == ''
  end

  def runner_start
    output, status = runner.start(kata_id, avatar_name)
    assert_equal success, status
    @rm_volume = output.strip
    [ output, status ]
  end

  def language_files(language_dir)
    dir = "/app/test/src/language_start_files/#{language_dir}"
    json = JSON.parse(IO.read("#{dir}/manifest.json"))
    @image_name = json['image_name']
    Hash[json['filenames'].collect { |filename|
      [filename, IO.read("#{dir}/#{filename}")]
    }]
  end

  def runner_run(changed_files, max_seconds = 10, delete_filenames = [])
    refute_nil @image_name
    @cid = runner.create_container(@image_name, kata_id, avatar_name)
    #...
    runner.run(@cid, max_seconds, delete_filenames, changed_files)
  end

  def remove_volume(name)
    # docker_runner.sh does [docker rm --force ${cid}] in a child process.
    # This has a race condition so you need to wait
    # until the container (which has the volume mounted)
    # is 'actually' removed before you can remove the volume.
    unless @cid.nil?
      10.times do
        break if container_dead?
        sleep(1)
      end
    end
    _output, status = exec("docker volume rm #{name} 2>&1")
    assert_equal success, status
    #puts "remove_volume output:#{output}:"
    #puts "remove_volume status:#{status}:"
  end

  def container_dead?
    refute_nil @cid
    command = "docker inspect --format='{{ .State.Running }}' #{@cid} 2> /dev/null"
    _output, status = exec(command)
    #p "inspect output:#{output}:"
    #p "inspect status:#{status}:"
    status == 1
  end

  def runner; DockerRunner.new(self); end
  def success; 0; end
  def timed_out_and_killed; (timeout = 128) + (kill = 9); end
  def kata_id; test_id; end
  def avatar_name; 'salmon'; end
  def volume_name; 'cyber_dojo_' + kata_id + '_' + avatar_name; end

  include Externals # for shell
  def exec(command); shell.exec(command); end

end

