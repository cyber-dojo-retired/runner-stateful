require_relative 'docker_runner_mix_in'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Recommended only for private cyber-dojo servers.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Uses a new long-lived container per kata.
# Each avatar's run() [docker exec]s a new process inside
# the kata's container.
#
# Negatives:
#   o) long-lived container per run() is harder to secure.
#
# Positives:
#   o) avatars can share state.
#   o) opens the way to avatars sharing processes.
#   o) fastest run(). In a rough sample
#      ~30% faster than KataVolumeRunner
# - - - - - - - - - - - - - - - - - - - - - - - - - - - -

class DockerKataContainerRunner

  include DockerRunnerMixIn

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # kata
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def kata_exists?
    name = container_name
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

  def new_kata
    refute_kata_exists
    # The container may have exited but its
    # volume may not have been collected yet.
    name = container_name
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
      '--ulimit nproc=64:64',              # max number processes = 64
      '--ulimit core=0:0',                 # max core file size = 0 blocks
      '--ulimit nofile=128:128',           # max number of files = 128
      '--user=root',
      "--volume #{name}:#{sandboxes_root_dir}:rw"
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

    assert_docker_exec(add_group_cmd)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def old_kata
    assert_kata_exists
    name = container_name
    assert_exec(remove_container_cmd(name))
    assert_exec(remove_volume_cmd(name))
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # avatar
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def avatar_exists?(avatar_name)
    assert_kata_exists
    assert_valid_avatar_name(avatar_name)
    id_cmd = docker_cmd("id -u #{avatar_name}")
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

  def new_avatar(avatar_name, starting_files)
    assert_kata_exists
    refute_avatar_exists(avatar_name)
    make_shared_dir
    chown_shared_dir
    add_avatar_user(avatar_name)
    make_avatar_dir(avatar_name)
    chown_avatar_dir(avatar_name)
    write_files(avatar_name, starting_files)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def old_avatar(avatar_name)
    assert_kata_exists
    assert_avatar_exists(avatar_name)
    delete_avatar_user(avatar_name)
    remove_avatar_dir(avatar_name)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # run
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def run(avatar_name, deleted_filenames, changed_files, max_seconds)
    assert_kata_exists
    assert_avatar_exists(avatar_name)
    delete_files(avatar_name, deleted_filenames)
    write_files(avatar_name, changed_files)
    stdout,stderr,status = run_cyber_dojo_sh(avatar_name, max_seconds)
    { stdout:stdout, stderr:stderr, status:status }
  end

  private

  def add_avatar_user(avatar_name)
    assert_docker_exec(add_user_cmd(avatar_name))
  end

  def delete_avatar_user(avatar_name)
    assert_docker_exec(del_user_cmd(avatar_name))
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def make_avatar_dir(avatar_name)
    dir = avatar_dir(avatar_name)
    assert_docker_exec("mkdir -m 755 #{dir}")
  end

  def chown_avatar_dir(avatar_name)
    dir = avatar_dir(avatar_name)
    assert_docker_exec("chown #{avatar_name}:#{group} #{dir}")
  end

  def remove_avatar_dir(avatar_name)
    dir = avatar_dir(avatar_name)
    assert_docker_exec("rm -rf #{dir}")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def make_shared_dir
    # first avatar makes the shared dir
    assert_docker_exec("mkdir -m 775 #{shared_dir} || true")
  end

  def chown_shared_dir
    assert_docker_exec("chown root:#{group} #{shared_dir}")
  end

  def shared_dir
    "#{sandboxes_root_dir}/shared"
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def delete_files(avatar_name, filenames)
    return if filenames == []
    dir = avatar_dir(avatar_name)
    filenames.each do |filename|
      assert_docker_exec("rm #{dir}/#{filename}")
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def write_files(avatar_name, files)
    return if files == {}
    cid = container_name
    dir = avatar_dir(avatar_name)
    Dir.mktmpdir('runner') do |tmp_dir|
      files.each do |filename, content|
        host_filename = tmp_dir + '/' + filename
        disk.write(host_filename, content)
      end
      assert_exec("docker cp #{tmp_dir}/. #{cid}:#{dir}")
      files.keys.each do |filename|
        chown_file = "chown #{avatar_name}:#{group} #{dir}/#{filename}"
        assert_docker_exec(chown_file)
      end
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def run_cyber_dojo_sh(avatar_name, max_seconds)
    # The processes __inside__ the docker container
    # are killed by /usr/local/bin/timeout_cyber_dojo.sh
    # See new_kata() above.
    sh_cmd = [
      '/usr/local/bin/timeout_cyber_dojo.sh',
      kata_id,
      avatar_name,
      max_seconds
    ].join(space)
    run_timeout(docker_cmd(sh_cmd), max_seconds)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def add_group_cmd
    return alpine_add_group_cmd if alpine?
    return ubuntu_add_group_cmd if ubuntu?
  end

  def add_user_cmd(avatar_name)
    return alpine_add_user_cmd(avatar_name) if alpine?
    return ubuntu_add_user_cmd(avatar_name) if ubuntu?
  end

  def del_user_cmd(avatar_name)
    return "deluser --remove-home #{avatar_name}" if alpine?
    return "userdel --remove #{avatar_name}"      if ubuntu?
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def alpine?
    etc_issue.include?('Alpine')
  end

  def ubuntu?
    etc_issue.include?('Ubuntu')
  end

  def etc_issue
    @ss ||= assert_docker_exec('cat /etc/issue')
    @ss[stdout=0]
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

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

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_avatar_exists(avatar_name)
    unless avatar_exists?(avatar_name)
      fail_avatar_name('!exists')
    end
  end

  def refute_avatar_exists(avatar_name)
    if avatar_exists?(avatar_name)
      fail_avatar_name('exists')
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_docker_exec(cmd)
    assert_exec(docker_cmd(cmd))
  end

  def docker_cmd(cmd)
    "docker exec #{container_name} sh -c '#{cmd}'"
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def container_name
    'cyber_dojo_kata_container_runner_' + kata_id
  end

  def remove_container_cmd(name)
    "docker rm --force #{name}"
  end

end
