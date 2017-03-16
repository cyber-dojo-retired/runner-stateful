require_relative 'docker_runner_mix_in'

module DockerRunnerVolumeMixIn

  include DockerRunnerMixIn

  module_function

  def in_container(avatar_name, volume_name, volume_root_dir, &block)
    cid = create_container(avatar_name, volume_name, volume_root_dir)
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
    args = [
      '--detach',                          # get the cid
      '--interactive',                     # for later execs
      '--net=none',                        # for security
      '--pids-limit=64',                   # no fork bombs
      '--security-opt=no-new-privileges',  # no escalation
      '--ulimit nproc=64:64',              # max number processes = 64
      '--ulimit core=0:0',                 # max core file size = 0 blocks
      '--ulimit nofile=128:128',           # max number of files = 128
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

  # - - - - - - - - - - - - - - - - - - - - - -

  def remove_container(cid)
    assert_exec("docker rm --force #{cid}")
    # The docker daemon responds to [docker rm]
    # asynchronously...
    # An 'immediately' following old_avatar()'s
    #    [docker volume rm]
    # might fail since the container is not quite dead yet.
    # This is unlikely to happen in real use but quite
    # likely in tests. I considered making old_avatar()
    # check the container was dead.
    #   pro) remove_container will never do a sleep
    #        (delaying a run)
    #   con) would mean storing the cid in the volume
    #        somewhere
    # I'm waiting max 2 seconds for the container to die.
    # o) no delay if container_dead? is true 1st time.
    # o) 0.04s delay if container_dead? is true 2nd time.
    removed = false
    tries = 0
    while !removed && tries < 50
      removed = container_dead?(cid)
      sleep(1.0 / 25.0) unless removed
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

  def delete_files(cid, avatar_name, filenames)
    return if filenames == []
    dir = avatar_dir(avatar_name)
    filenames.each do |filename|
      assert_docker_exec(cid, "rm #{dir}/#{filename}")
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def write_files(cid, avatar_name, files)
    return if files == {}
    dir = avatar_dir(avatar_name)
    Dir.mktmpdir('runner') do |tmp_dir|
      files.each do |filename, content|
        host_filename = tmp_dir + '/' + filename
        disk.write(host_filename, content)
      end
      assert_exec("docker cp #{tmp_dir}/. #{cid}:#{dir}")
      files.keys.each do |filename|
        chown_file = "chown #{avatar_name}:#{group} #{dir}/#{filename}"
        assert_docker_exec(cid, chown_file)
      end
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def run_cyber_dojo_sh(cid, avatar_name, max_seconds)
    # I thought doing [chmod 755] in new_avatar() would
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
    stdout,_ = assert_exec("docker volume ls --quiet --filter 'name=#{name}'")
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

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_docker_exec(cid, cmd)
    assert_exec("docker exec #{cid} sh -c '#{cmd}'")
  end

end

