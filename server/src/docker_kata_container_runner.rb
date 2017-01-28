require_relative 'docker_runner_mix_in'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Uses a new long-lived container per kata.
# Each avatar's run() [docker exec]s a new process inside
# the kata's container.
#
# Positives:
#   o) avatars can share state.
#   o) opens the way to avatars sharing processes.
#   o) fastest run(). In a rough sample
#      ~20% faster than AvatarVolumeRunner
#      ~30% faster than KataVolumeRunner
#
# Negatives:
#   o) the cyber-dojo.sh process is not running as
#      pid-1. A pid-1 process is a robust way of
#      killing an entire process tree.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - -

class DockerKataContainerRunner

  include DockerRunnerMixIn

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # kata
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def kata_exists?(_image_name, kata_id)
    assert_valid_id(kata_id)

    name = container_name(kata_id)
    cmd = [
      'docker ps',
        '--quiet',
        '--all',
        '--filter status=running',
        "--filter name=#{name}"
    ].join(space)
    stdout,_ = assert_exec(cmd)
    stdout.strip != ''
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def new_kata(image_name, kata_id)
    refute_kata_exists(kata_id)

    # The container may have exited
    # but not been collected yet.
    name = container_name(kata_id)
    quiet_exec(remove_container_cmd(name))
    quiet_exec(remove_volume_cmd(name))

    assert_exec(create_volume_cmd(name))
    args = [
      '--detach',
      '--interactive',                     # later execs
      "--name=#{name}",
      '--net=none',                        # security
      '--pids-limit=256',                  # no fork bombs
      '--security-opt=no-new-privileges',  # no escalation
      '--user=root',
      "--volume #{name}:#{sandboxes_root}:rw"
    ].join(space)
    cmd = "docker run #{args} #{image_name} sh -c 'sleep 3h'"
    assert_exec(cmd)

    my_dir = File.expand_path(File.dirname(__FILE__))
    docker_cp = [
      'docker cp',
      "#{my_dir}/timeout_cyber_dojo.sh",
      "#{name}:/usr/local/bin"
    ].join(space)
    assert_exec(docker_cp)

    assert_docker_exec(kata_id, add_group_cmd(kata_id))
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def old_kata(_image_name, kata_id)
    assert_kata_exists(kata_id)

    name = container_name(kata_id)
    assert_exec(remove_container_cmd(name))
    assert_exec(remove_volume_cmd(name))
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # avatar
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def avatar_exists?(_image_name, kata_id, avatar_name)
    assert_kata_exists(kata_id)
    assert_valid_name(avatar_name)

    id_cmd = docker_cmd(kata_id, "id -u #{avatar_name}")
    stdout,_,status = quiet_exec(id_cmd)
    # Alpine Linux has an existing proxy-server user
    # called squid (uid=31) which I have to work around.
    # See alpine_add_user_cmd() in docker_runner_mix_in.rb
    if avatar_name == 'squid' && stdout.strip == '31'
      false
    else
      status == success
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def new_avatar(_image_name, kata_id, avatar_name, starting_files)
    assert_kata_exists(kata_id)
    refute_avatar_exists(kata_id, avatar_name)

    add_user = add_user_cmd(kata_id, avatar_name)
    assert_docker_exec(kata_id, add_user)

    sandbox = sandbox_path(avatar_name)
    mkdir = "mkdir -m 755 #{sandbox}"
    chown = "chown #{avatar_name}:#{group} #{sandbox}"
    assert_docker_exec(kata_id, [ mkdir, chown ].join(' && '))

    write_files(kata_id, avatar_name, starting_files)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def old_avatar(_image_name, kata_id, avatar_name)
    assert_kata_exists(kata_id)
    assert_avatar_exists(kata_id, avatar_name)

    del_user = del_user_cmd(kata_id, avatar_name)
    assert_docker_exec(kata_id, del_user)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # run
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def run(_image_name, kata_id, avatar_name, deleted_filenames, changed_files, max_seconds)
    assert_kata_exists(kata_id)
    assert_avatar_exists(kata_id, avatar_name)

    delete_files(kata_id, avatar_name, deleted_filenames)
    write_files(kata_id, avatar_name, changed_files)
    stdout,stderr,status = run_cyber_dojo_sh(kata_id, avatar_name, max_seconds)
    { stdout:stdout, stderr:stderr, status:status }
  end

  private

  def delete_files(kata_id, avatar_name, filenames)
    return if filenames == []
    sandbox = sandbox_path(avatar_name)
    all = filenames.map { |filename| "#{sandbox}/#{filename}" }
    rm = 'rm ' + all.join(space)
    assert_docker_exec(kata_id, rm)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def write_files(kata_id, avatar_name, files)
    return if files == {}
    Dir.mktmpdir('runner') do |tmp_dir|
      files.each do |filename, content|
        host_filename = tmp_dir + '/' + filename
        disk.write(host_filename, content)
      end
      cid = container_name(kata_id)
      sandbox = sandbox_path(avatar_name)
      docker_cp = "docker cp #{tmp_dir}/. #{cid}:#{sandbox}"
      assert_exec(docker_cp)
      all = files.keys.map { |filename| "#{sandbox}/#{filename}" }
      chown = "chown #{avatar_name}:#{group} " + all.join(space)
      assert_docker_exec(kata_id, chown)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def run_cyber_dojo_sh(kata_id, avatar_name, max_seconds)
    # The processes __inside__ the docker container
    # are killed by /usr/local/bin/timeout_cyber_dojo.sh
    # See new_kata() above.
    sh_cmd = [
      '/usr/local/bin/timeout_cyber_dojo.sh',
      kata_id,
      avatar_name,
      max_seconds
    ].join(space)
    run_timeout(docker_cmd(kata_id, sh_cmd), max_seconds)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def add_group_cmd(kata_id)
    if alpine? kata_id
      return alpine_add_group_cmd
    end
    if ubuntu? kata_id
      return ubuntu_add_group_cmd
    end
  end

  def add_user_cmd(kata_id, avatar_name)
    if alpine?(kata_id)
      return alpine_add_user_cmd(avatar_name)
    end
    if ubuntu?(kata_id)
      return ubuntu_add_user_cmd(avatar_name)
    end
  end

  def del_user_cmd(kata_id, avatar_name)
    if alpine? kata_id
      return "deluser --remove-home #{avatar_name}"
    end
    if ubuntu? kata_id
      return "userdel --remove #{avatar_name}"
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def alpine?(kata_id)
    etc_issue(kata_id).include?('Alpine')
  end

  def ubuntu?(kata_id)
    etc_issue(kata_id).include?('Ubuntu')
  end

  def etc_issue(kata_id)
    stdout,_ = assert_docker_exec(kata_id, 'cat /etc/issue')
    stdout
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_kata_exists(kata_id)
    assert_valid_id(kata_id)
    unless kata_exists?(nil, kata_id)
      fail_kata_id('!exists')
    end
  end

  def refute_kata_exists(kata_id)
    assert_valid_id(kata_id)
    if kata_exists?(nil, kata_id)
      fail_kata_id('exists')
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_avatar_exists(kata_id, avatar_name)
    assert_valid_name(avatar_name)
    unless avatar_exists?(nil, kata_id, avatar_name)
      fail_avatar_name('!exists')
    end
  end

  def refute_avatar_exists(kata_id, avatar_name)
    assert_valid_name(avatar_name)
    if avatar_exists?(nil, kata_id, avatar_name)
      fail_avatar_name('exists')
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_docker_exec(kata_id, cmd)
    assert_exec(docker_cmd(kata_id, cmd))
  end

  def docker_cmd(kata_id, cmd)
    name = container_name(kata_id)
    "docker exec #{name} sh -c '#{cmd}'"
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def container_name(kata_id)
    'cyber_dojo_kata_container_runner_' + kata_id
  end

  def remove_container_cmd(name)
    "docker rm --force #{name}"
  end

end
