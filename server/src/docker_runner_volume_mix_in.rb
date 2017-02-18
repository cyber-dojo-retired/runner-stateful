require_relative 'docker_runner_mix_in'

module DockerRunnerVolumeMixIn

  include DockerRunnerMixIn

  module_function

  def in_container(avatar_name, volume_name, volume_root, &block)
    cid = create_container(avatar_name, volume_name, volume_root)
    begin
      block.call(cid)
    ensure
      remove_container(cid)
    end
  end

  def create_container(avatar_name, volume_name, volume_root)
    # The [docker run] must be guarded by argument checks
    # because it volume mounts...
    #     [docker run ... --volume=V:...]
    # Volume V must already exist.
    # If volume V does _not_ exist the [docker run]
    # will nevertheless succeed, create the container,
    # and create a temporary /sandboxes/ folder in it!
    # See https://github.com/docker/docker/issues/13121

    sandbox = sandbox_dir(avatar_name)
    home = home_dir(avatar_name)
    args = [
      '--detach',                          # get the cid
      '--interactive',                     # later execs
      '--net=none',                        # security
      '--pids-limit=64',                   # no fork bombs
      '--security-opt=no-new-privileges',  # no escalation
      "--env CYBER_DOJO_KATA_ID=#{kata_id}",
      "--env CYBER_DOJO_AVATAR_NAME=#{avatar_name}",
      "--env CYBER_DOJO_SANDBOX=#{sandbox}",
      "--env HOME=#{home}",
      '--user=root',
      "--volume #{volume_name}:#{volume_root}:rw"
    ].join(space)
    stdout,_ = assert_exec("docker run #{args} #{image_name} sh")
    cid = stdout.strip
    assert_docker_exec(cid, add_group_cmd(cid))
    assert_docker_exec(cid, add_user_cmd(cid, avatar_name))
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

  def add_group_cmd(cid)
    if alpine? cid
      return alpine_add_group_cmd
    end
    if ubuntu? cid
      return ubuntu_add_group_cmd
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def add_user_cmd(cid, avatar_name)
    if alpine? cid
      return alpine_add_user_cmd(avatar_name)
    end
    if ubuntu? cid
      return ubuntu_add_user_cmd(avatar_name)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def alpine?(cid)
    etc_issue(cid).include?('Alpine')
  end

  def ubuntu?(cid)
    etc_issue(cid).include?('Ubuntu')
  end

  def etc_issue(cid)
    stdout,_ = assert_docker_exec(cid, 'cat /etc/issue')
    stdout
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def chown_sandbox_dir(cid, avatar_name)
    sandbox = sandbox_dir(avatar_name)
    uid = user_id(avatar_name)
    chown = "chown #{uid}:#{gid} #{sandbox}"
    assert_docker_exec(cid, chown)
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def delete_files(cid, avatar_name, filenames)
    return if filenames == []
    sandbox = sandbox_dir(avatar_name)
    all = filenames.map { |filename| "#{sandbox}/#{filename}" }
    rm = 'rm ' + all.join(space)
    assert_docker_exec(cid, rm)
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def write_files(cid, avatar_name, files)
    return if files == {}
    Dir.mktmpdir('runner') do |tmp_dir|
      files.each do |filename, content|
        host_filename = tmp_dir + '/' + filename
        disk.write(host_filename, content)
      end
      uid = user_id(avatar_name)
      sandbox = sandbox_dir(avatar_name)
      docker_cp = "docker cp #{tmp_dir}/. #{cid}:#{sandbox}"
      assert_exec(docker_cp)
      all = files.keys.map { |filename| "#{sandbox}/#{filename}" }
      chown = "chown #{uid}:#{gid} " + all.join(space)
      assert_docker_exec(cid, chown)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - -

  def run_cyber_dojo_sh(cid, avatar_name, max_seconds)
    # I thought doing [chmod 755] in new_avatar() would
    # be "sticky" and remain 755 but it appears not...
    uid = user_id(avatar_name)
    sandbox = sandbox_dir(avatar_name)
    docker_cmd = [
      'docker exec',
      "--user=#{uid}:#{gid}",
      '--interactive',
      cid,
      "sh -c 'cd #{sandbox} && chmod 755 . && sh ./cyber-dojo.sh'"
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

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_docker_exec(cid, cmd)
    assert_exec("docker exec #{cid} sh -c '#{cmd}'")
  end

end

