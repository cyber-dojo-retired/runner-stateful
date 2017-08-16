require_relative 'docker_runner_mix_in'
require 'securerandom'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Uses a new short-lived docker container per run().
# Uses a long-lived docker volume per kata.
#
# Positives:
#   o) long-lived container per run() is harder to secure.
#   o) avatars can share state (eg sqlite database
#      in /sandboxes/shared)
#
# Negatives:
#   o) avatars cannot share processes.
#   o) bit slower than SharedContainerRunner.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

class SharedVolumeRunner

  include DockerRunnerMixIn

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # kata
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def kata_exists?
    volume_exists?(kata_volume_name)
  end

  def kata_new
    refute_kata_exists
    create_volume(kata_volume_name)
  end

  def kata_old
    assert_kata_exists
    remove_volume(kata_volume_name)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # avatar
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def avatar_exists?(avatar_name)
    assert_kata_exists
    assert_valid_avatar_name(avatar_name)
    in_container(avatar_name) do |cid|
      avatar_exists_cid?(cid, avatar_name)
    end
  end

  def avatar_new(avatar_name, starting_files)
    assert_kata_exists
    assert_valid_avatar_name(avatar_name)
    in_container(avatar_name) do |cid|
      refute_avatar_exists(cid, avatar_name)
      make_shared_dir(cid)
      chown_shared_dir(cid)
      make_avatar_dir(cid, avatar_name)
      chown_avatar_dir(cid, avatar_name)
      write_files(cid, avatar_name, starting_files)
    end
  end

  def avatar_old(avatar_name)
    assert_kata_exists
    assert_valid_avatar_name(avatar_name)
    in_container(avatar_name) do |cid|
      assert_avatar_exists(cid, avatar_name)
      remove_avatar_dir(cid, avatar_name)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # run
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Copes with infinite loops (eg) in the avatar's
  # code/tests by removing the container - which kills
  # all processes running inside the container.
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def run(avatar_name, deleted_filenames, changed_files, max_seconds)
    assert_kata_exists
    assert_valid_avatar_name(avatar_name)
    in_container(avatar_name) do |cid|
      assert_avatar_exists(cid, avatar_name)
      delete_files(cid, avatar_name, deleted_filenames)
      write_files(cid, avatar_name, changed_files)
      stdout,stderr,status = run_cyber_dojo_sh(cid, avatar_name, max_seconds)
      colour = red_amber_green(cid, stdout, stderr, status)
      { stdout:stdout, stderr:stderr, status:status, colour:colour }
    end
  end

  private

  def in_container(avatar_name, &block)
    cid = create_container(avatar_name, kata_volume_name, sandboxes_root_dir)
    begin
      block.call(cid)
    ensure
      remove_container(cid)
    end
  end

  def create_container(avatar_name, volume_name, volume_root)
    # The [docker run] must be guarded by argument checks
    # because it volume mounts...
    #     [docker run ... --volume ...]
    # Volume V must already exist.
    # If volume V does _not_ exist the [docker run]
    # will nevertheless succeed, create the container,
    # and create a temporary /sandboxes/ folder in it!
    # See https://github.com/docker/docker/issues/13121

    dir = avatar_dir(avatar_name)
    home = home_dir(avatar_name)
    name = "test_run__runner_stateful_#{kata_id}_#{avatar_name}_#{uuid}"
    max = 128
    args = [
      '--detach',                          # get the cid
      '--interactive',                     # for later execs
      "--name=#{name}",                    # for easy clean up
      '--net=none',                        # for security
      '--security-opt=no-new-privileges',  # no escalation
      "--pids-limit=#{max}",               # no fork bombs
      "--ulimit nproc=#{max}:#{max}",      # max number processes
      "--ulimit nofile=#{max}:#{max}",     # max number of files
      '--ulimit core=0:0',                 # max core file size = 0 blocks
      "--env CYBER_DOJO_KATA_ID=#{kata_id}",
      "--env CYBER_DOJO_AVATAR_NAME=#{avatar_name}",
      "--env CYBER_DOJO_SANDBOX=#{dir}",
      "--env HOME=#{home}",
      '--user=root',
      "--volume #{volume_name}:#{volume_root}:rw"
    ].join(space)
    stdout,_ = assert_exec("docker run #{args} #{image_name} sh")
    cid = stdout.strip
    add_user_and_group(cid, avatar_name)
    cid
  end

  def uuid
    SecureRandom.hex[0..10].upcase
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def remove_container(cid)
    assert_exec("docker rm --force #{cid}")
    # The docker daemon responds to [docker rm]
    # asynchronously...
    # An 'immediately' following avatar_old()'s
    #    [docker volume rm]
    # might fail since the container is not quite dead yet.
    # This is unlikely to happen in real use but quite
    # likely in tests.
    # I'm waiting max 2 seconds for the container to die.
    # o) no delay if container_dead? is true 1st time.
    # o) 0.04s delay if container_dead? is true 2nd time, etc.
    removed = false
    tries = 0
    while !removed && tries < 50
      removed = container_dead?(cid)
      assert_exec("sleep #{1.0 / 25.0}") unless removed
      tries += 1
    end
    log << "Failed:remove_container(#{cid})" unless removed
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def container_dead?(cid)
    cmd = "docker inspect --format='{{ .State.Running }}' #{cid}"
    _,stderr,status = quiet_exec(cmd)
    expected_stderr = "Error: No such image, container or task: #{cid}"
    (status == 1) && (stderr.strip == expected_stderr)
  end

  # - - - - - - - - - - - - - - - - - - - - - -
  # - - - - - - - - - - - - - - - - - - - - - -

  def add_user_and_group(cid, avatar_name)
    assert_docker_exec(cid,
      [
        add_group_cmd(cid),
        add_user_cmd(cid, avatar_name)
      ].join(' && ')
    )
  end

  def add_group_cmd(cid)
    return alpine_add_group_cmd if alpine? cid
    return ubuntu_add_group_cmd if ubuntu? cid
  end

  def add_user_cmd(cid, avatar_name)
    return alpine_add_user_cmd(avatar_name) if alpine? cid
    return ubuntu_add_user_cmd(avatar_name) if ubuntu? cid
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def alpine?(cid)
    etc_issue(cid).include?('Alpine')
  end

  def ubuntu?(cid)
    etc_issue(cid).include?('Ubuntu')
  end

  def etc_issue(cid)
    @ss ||= assert_docker_exec(cid, 'cat /etc/issue')
    @ss[stdout=0]
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def chown_avatar_dir(cid, avatar_name)
    uid = user_id(avatar_name)
    dir = avatar_dir(avatar_name)
    assert_docker_exec(cid, "chown #{uid}:#{gid} #{dir}")
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def run_cyber_dojo_sh(cid, avatar_name, max_seconds)
    # I thought doing [chmod 755] in avatar_new() would
    # be "sticky" and remain 755 but it appears not...
    uid = user_id(avatar_name)
    dir = avatar_dir(avatar_name)
    docker_cmd = [
      'docker exec',
      "--user=#{uid}:#{gid}",
      '--interactive',
      cid,
      "sh -c 'cd #{dir} && chmod 755 . && sh ./cyber-dojo.sh'"
    ].join(space)

    run_timeout(docker_cmd, max_seconds)
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def volume_exists?(name)
    cmd = "docker volume ls --quiet --filter 'name=#{name}'"
    stdout,_ = assert_exec(cmd)
    stdout.strip != ''
  end

  def create_volume(name)
    assert_exec(create_volume_cmd(name))
  end

  def remove_volume(name)
    assert_exec(remove_volume_cmd(name))
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_kata_exists
    unless kata_exists?
      fail_kata_id('!exists')
    end
  end

  def refute_kata_exists
    if kata_exists?
      fail_kata_id('exists')
    end
  end

  def assert_docker_exec(cid, cmd)
    assert_exec("docker exec #{cid} sh -c '#{cmd}'")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def make_avatar_dir(cid, avatar_name)
    dir = avatar_dir(avatar_name)
    assert_docker_exec(cid, "mkdir -m 755 #{dir}")
  end

  def remove_avatar_dir(cid, avatar_name)
    dir = avatar_dir(avatar_name)
    assert_docker_exec(cid, "rm -rf #{dir}")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def make_shared_dir(cid)
    # first avatar makes the shared dir
    assert_docker_exec(cid, "mkdir -m 775 #{shared_dir} || true")
  end

  def chown_shared_dir(cid)
    assert_docker_exec(cid, "chown root:#{group} #{shared_dir}")
  end

  def shared_dir
    "#{sandboxes_root_dir}/shared"
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_avatar_exists(cid, avatar_name)
    unless avatar_exists_cid?(cid, avatar_name)
      fail_avatar_name('!exists')
    end
  end

  def refute_avatar_exists(cid, avatar_name)
    if avatar_exists_cid?(cid, avatar_name)
      fail_avatar_name('exists')
    end
  end

  def avatar_exists_cid?(cid, avatar_name)
    dir = avatar_dir(avatar_name)
    _,_,status = quiet_exec("docker exec #{cid} sh -c '[ -d #{dir} ]'")
    status == success
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def kata_volume_name
    'cyber_dojo_kata_volume_runner_' + kata_id
  end

end
