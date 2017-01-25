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

  def kata_exists?(_image_name, kata_id)
    assert_valid_id(kata_id)
    volume_exists?(kata_volume_name(kata_id))
  end

  def new_kata(image_name, kata_id)
    refute_kata_exists(image_name, kata_id)
    create_volume(kata_volume_name(kata_id))
  end

  def old_kata(image_name, kata_id)
    assert_kata_exists(image_name, kata_id)
    remove_volume(kata_volume_name(kata_id))
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # avatar
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def avatar_exists?(image_name, kata_id, avatar_name)
    assert_valid_id(kata_id)
    assert_kata_exists(image_name, kata_id)
    assert_valid_name(avatar_name)
    volume_name = kata_volume_name(kata_id)
    volume_root = sandboxes_root
    cid = create_container(image_name, kata_id, avatar_name, volume_name, volume_root)
    begin
      avatar_exists_cid?(cid, avatar_name)
    ensure
      remove_container(cid)
    end
  end

  def new_avatar(image_name, kata_id, avatar_name, starting_files)
    assert_valid_id(kata_id)
    assert_kata_exists(image_name, kata_id)
    assert_valid_name(avatar_name)
    volume_name = kata_volume_name(kata_id)
    volume_root = sandboxes_root
    cid = create_container(image_name, kata_id, avatar_name, volume_name, volume_root)
    begin
      refute_avatar_exists(cid, avatar_name)
      make_sandbox(cid, avatar_name)
      chown_sandbox(cid, avatar_name)
      write_files(cid, avatar_name, starting_files)
    ensure
      remove_container(cid)
    end
  end

  def old_avatar(image_name, kata_id, avatar_name)
    assert_valid_id(kata_id)
    assert_kata_exists(image_name, kata_id)
    assert_valid_name(avatar_name)
    volume_name = kata_volume_name(kata_id)
    volume_root = sandboxes_root
    cid = create_container(image_name, kata_id, avatar_name, volume_name, volume_root)
    begin
      assert_avatar_exists(cid, avatar_name)
      sandbox = sandbox_path(avatar_name)
      rm = "rm -rf #{sandbox}"
      assert_docker_exec(cid, rm)
    ensure
      remove_container(cid)
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # run
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Copes with infinite loops (eg) in the avatar's
  # code/tests by removing the container - which
  # obviously kills all processes running inside
  # the container.
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def run(image_name, kata_id, avatar_name, deleted_filenames, changed_files, max_seconds)
    assert_valid_id(kata_id)
    assert_kata_exists(image_name, kata_id)
    assert_valid_name(avatar_name)
    volume_name = kata_volume_name(kata_id)
    volume_root = sandboxes_root
    cid = create_container(image_name, kata_id, avatar_name, volume_name, volume_root)
    begin
      assert_avatar_exists(cid, avatar_name)
      delete_files(cid, avatar_name, deleted_filenames)
      write_files(cid, avatar_name, changed_files)
      stdout,stderr,status = run_cyber_dojo_sh(cid, avatar_name, max_seconds)
      { stdout:stdout, stderr:stderr, status:status }
    ensure
      remove_container(cid)
    end
  end

  private

  def make_sandbox(cid, avatar_name)
    sandbox = sandbox_path(avatar_name)
    mkdir = "mkdir -m 755 #{sandbox}"
    assert_docker_exec(cid, mkdir)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_kata_exists(image_name, kata_id)
    unless kata_exists?(image_name, kata_id)
      fail_kata_id('!exists')
    end
  end

  def refute_kata_exists(image_name, kata_id)
    if kata_exists?(image_name, kata_id)
      fail_kata_id('exists')
    end
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

  def kata_volume_name(kata_id)
    'cyber_dojo_kata_volume_runner_' + kata_id
  end

end
