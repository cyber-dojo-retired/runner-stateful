require_relative 'docker_runner_volume_mix_in'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Uses a new short-lived docker container per run().
# Uses a long-lived docker volume per avatar.
#
# Positives:
#   o) the cyber-dojo.sh process is running as pid-1
#      which is a robust way of ensuring the entire
#      process tree is killed.
#
# Negatives:
#   o) increased run() time (compared to one container per kata)
#   o) no possibility of avatars sharing state or processes.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

class DockerAvatarVolumeRunner

  include DockerRunnerVolumeMixIn

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # kata
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def kata_exists?(image_name, kata_id)
    assert_valid_id(kata_id)

    name = kata_volume_container_name(kata_id)
    cmd = "docker ps --quiet --all --filter name=#{name}"
    stdout,_ = assert_exec(cmd)
    stdout.strip != ''
  end

  def new_kata(image_name, kata_id)
    refute_kata_exists(kata_id)

    name = kata_volume_container_name(kata_id)
    cmd = [
      'docker run',
        "--name=#{name}",
        image_name,
        '/bin/true'
    ].join(space)
    assert_exec(cmd)
  end

  def old_kata(image_name, kata_id)
    assert_kata_exists(kata_id)

    name = kata_volume_container_name(kata_id)
    cmd = "docker rm --volumes #{name}"
    assert_exec(cmd)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # avatar
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def avatar_exists?(image_name, kata_id, avatar_name)
    assert_valid_id(kata_id)
    assert_kata_exists(kata_id)
    assert_valid_name(avatar_name)

    name = avatar_volume_container_name(kata_id, avatar_name)
    cmd = "docker ps --quiet --all --filter name=#{name}"
    stdout,_ = assert_exec(cmd)
    stdout.strip != ''
  end

  def new_avatar(image_name, kata_id, avatar_name, starting_files)
    assert_valid_id(kata_id)
    assert_kata_exists(kata_id)
    refute_avatar_exists(kata_id, avatar_name)

    name = avatar_volume_container_name(kata_id, avatar_name)
    cmd = [
      'docker run',
        "--volume #{sandboxes_root}",
        "--name=#{name}",
        image_name,
        '/bin/true'
    ].join(space)
    assert_exec(cmd)

    cid = create_container(image_name, kata_id, avatar_name)
    begin
      make_sandbox(cid, avatar_name)
      write_files(cid, avatar_name, starting_files)
    ensure
      remove_container(cid)
    end
  end

  def old_avatar(_image_name, kata_id, avatar_name)
    assert_kata_exists(kata_id)
    assert_avatar_exists(kata_id, avatar_name)

    name = avatar_volume_container_name(kata_id, avatar_name)
    cmd = "docker rm --volumes #{name}"
    assert_exec(cmd)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # run
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Copes with infinite loops (eg) in the avatar's code/tests by
  # removing the container - which obviously kills all processes
  # running inside the container.
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def run(image_name, kata_id, avatar_name, deleted_filenames, changed_files, max_seconds)
    assert_valid_id(kata_id)
    assert_kata_exists(kata_id)
    assert_avatar_exists(kata_id, avatar_name)

    cid = create_container(image_name, kata_id, avatar_name)
    begin
      delete_files(cid, avatar_name, deleted_filenames)
      write_files(cid, avatar_name, changed_files)
      stdout,stderr,status = run_cyber_dojo_sh(cid, avatar_name, max_seconds)
      { stdout:stdout, stderr:stderr, status:status }
    ensure
      remove_container(cid)
    end
  end

  private

  def create_container(image_name, kata_id, avatar_name)
    # Volume mounts the avatar's volume
    #     [docker run ... --volume=V:/sandbox  ...]
    # Volume V is assumed to exist via an earlier new_avatar() call.
    # If volume V does _not_ exist the [docker run] will nevertheless
    # succeed, create the container, and create a /sandbox folder in it!
    # https://github.com/docker/docker/issues/13121
    sandbox = sandbox_path(avatar_name)
    home = home_path(avatar_name)
    avcn = avatar_volume_container_name(kata_id, avatar_name)
    args = [
      '--detach',                          # get the cid
      '--interactive',                     # later execs
      '--net=none',                        # security - no network
      '--pids-limit=64',                   # security - no fork bombs
      '--security-opt=no-new-privileges',  # security - no escalation
      "--env CYBER_DOJO_KATA_ID=#{kata_id}",
      "--env CYBER_DOJO_AVATAR_NAME=#{avatar_name}",
      "--env CYBER_DOJO_SANDBOX=#{sandbox}",
      "--env HOME=#{home}",
      '--user=root',
      "--volumes-from=#{avcn}:rw"
    ].join(space)
    stdout,_ = assert_exec("docker run #{args} #{image_name} sh")
    cid = stdout.strip

    cmd = [
      add_group_cmd(cid),
      add_user_cmd(cid, avatar_name)
    ].join('&&')
    assert_docker_exec(cid, cmd)

    cid
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def assert_kata_exists(kata_id)
    unless kata_exists?(nil, kata_id)
      fail_kata_id('!exists')
    end
  end

  def refute_kata_exists(kata_id)
    if kata_exists?(nil, kata_id)
      fail_kata_id('exists')
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def assert_avatar_exists(kata_id, avatar_name)
    unless avatar_exists?(nil, kata_id, avatar_name)
      fail_avatar_name('!exists')
    end
  end

  def refute_avatar_exists(kata_id, avatar_name)
    if avatar_exists?(nil, kata_id, avatar_name)
      fail_avatar_name('exists')
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def kata_volume_container_name(kata_id)
    'cyber_dojo_avatar_volume_runner_' + kata_id + '_kata'
  end

  def avatar_volume_container_name(kata_id, avatar_name)
    'cyber_dojo_avatar_volume_runner_' + kata_id + '_' + avatar_name
  end

end
