
require_relative './null_logger'

module DockerRunnerHelpers # mix-in

  module_function

  def external_setup
    # TODO?: expose container's cid and ensure [docker rm #{cid}] happens in external_teardown
    assert_equal 'ExternalSheller', shell.class.name
    ENV[env_name('log')] = 'NullLogger'
    @rm_volume = ''
  end

  def external_teardown
    remove_volume(@rm_volume) unless @rm_volume == ''
  end

  def runner_start
    output, exit_status = runner.start(kata_id, avatar_name)
    assert_equal success, exit_status
    @rm_volume = output.strip
  end

  def runner_run(changed_files, delete_filenames = [], max_seconds = 3)
    output = runner.run(
      gcc_assert_image_name,
      kata_id,
      avatar_name,
      max_seconds,
      delete_filenames,
      changed_files)
  end

  def starting_files
    {
      'hiker.c'       => read('hiker.c'),
      'hiker.h'       => read('hiker.h'),
      'hiker.tests.c' => read('hiker.tests.c'),
      'cyber-dojo.sh' => read('cyber-dojo.sh'),
      'makefile'      => read('makefile')
    }
  end

  def remove_volume(name)
    # docker_runner.sh does [docker rm --force ${cid}] in a child process.
    # This has a race condition so you need to wait
    # until the container (which has the volume mounted)
    # is 'actually' removed before you can remove the volume.
    100.times do
      #p "about to [docker volume rm #{name}]"
      output, exit_status = exec("docker volume rm #{name} 2>&1")
      break if exit_status == success
      #p "[docker volume rm]exit_status=:#{exit_status}:"
      #p "[docker volume rm]output=:#{output}:"
    end
  end

  def exec(command)
    output, exit_success = shell.exec(command)
    return [output, exit_success]
  end

  def read(filename)
    IO.read("/app/test/src/start_files/#{filename}")
  end

  def runner; DockerRunner.new(self); end
  def success; 0; end
  def gcc_assert_image_name; 'cyberdojofoundation/gcc_assert'; end
  def kata_id; test_id; end
  def avatar_name; 'lion'; end
  def volume_name; 'cyber_dojo_' + kata_id + '_' + avatar_name; end

  include Externals # for shell

end

