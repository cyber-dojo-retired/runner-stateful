require_relative 'docker_runner_volume_mix_in'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Uses a new short-lived docker container per run().
# Uses a long-lived docker volume per kata.
#
# Positives:
#   o) avatars can share state.
#   o) the cyber-dojo.sh process is running as pid-1
#      which is a robust way of ensuring the entire
#      process tree is killed.
#
# Negatives:
#   o) avatars cannot share processes.
#   o) increased run() time
#      (compared to one container per kata)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

class DockerKataVolumeRunner

  include DockerRunnerVolumeMixIn

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # kata
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def kata_exists?
    volume_exists?(kata_volume_name)
  end

  def new_kata
    refute_kata_exists
    create_volume(kata_volume_name)
  end

  def old_kata
    assert_kata_exists
    remove_volume(kata_volume_name)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # avatar
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def avatar_exists?(avatar_name)
    assert_kata_exists
    assert_valid_avatar_name(avatar_name)

    in_kvr_container(avatar_name) do |cid|
      avatar_exists_cid?(cid, avatar_name)
    end
  end

  def new_avatar(avatar_name, starting_files)
    assert_kata_exists
    assert_valid_avatar_name(avatar_name)

    in_kvr_container(avatar_name) do |cid|
      refute_avatar_exists(cid, avatar_name)
      make_shared_folder(cid)
      make_sandbox(cid, avatar_name)
      chown_sandbox(cid, avatar_name)
      write_files(cid, avatar_name, starting_files)
    end
  end

  def old_avatar(avatar_name)
    assert_kata_exists
    assert_valid_avatar_name(avatar_name)

    in_kvr_container(avatar_name) do |cid|
      assert_avatar_exists(cid, avatar_name)
      remove_sandbox(cid, avatar_name)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # run
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Copes with infinite loops (eg) in the avatar's
  # code/tests by removing the container - which kills
  # kills all processes running inside the container.
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def run(avatar_name, deleted_filenames, changed_files, max_seconds)
    assert_kata_exists
    assert_valid_avatar_name(avatar_name)

    in_kvr_container(avatar_name) do |cid|
      assert_avatar_exists(cid, avatar_name)
      delete_files(cid, avatar_name, deleted_filenames)
      write_files(cid, avatar_name, changed_files)
      stdout,stderr,status = run_cyber_dojo_sh(cid, avatar_name, max_seconds)
      { stdout:stdout, stderr:stderr, status:status }
    end
  end

  private

  def in_kvr_container(avatar_name, &block)
    volume_name = kata_volume_name
    volume_root = sandboxes_root
    in_container(avatar_name, volume_name, volume_root, &block)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def make_sandbox(cid, avatar_name)
    sandbox = sandbox_path(avatar_name)
    mkdir = "mkdir -m 755 #{sandbox}"
    assert_docker_exec(cid, mkdir)
  end

  def remove_sandbox(cid, avatar_name)
    sandbox = sandbox_path(avatar_name)
    rmdir = "rm -rf #{sandbox}"
    assert_docker_exec(cid, rmdir)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def make_shared_folder(cid)
    shared_folder = "/sandboxes/shared"
    mkdir = "mkdir -m 775 #{shared_folder} || true" # idempotent
    assert_docker_exec(cid, mkdir)
    group = 'cyber-dojo'
    chown = "chown root:#{group} #{shared_folder}"
    assert_docker_exec(cid, chown)
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
    sandbox = sandbox_path(avatar_name)
    cmd = "docker exec #{cid} sh -c '[ -d #{sandbox} ]'"
    _,_,status = quiet_exec(cmd)
    status == success
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def kata_volume_name
    'cyber_dojo_kata_volume_runner_' + kata_id
  end

end
