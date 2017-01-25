require_relative 'docker_runner_volume_mix_in'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Uses a new short-lived docker container per run().
# Uses a long-lived docker volume per avatar.
#
# Positives:
#   o) the cyber-dojo.sh process is running as pid-1
#      which is a robust way of ensuring the entire
#      process tree is killed.
#
# Negatives:
#   o) no possibility of avatars sharing state or processes.
#   o) increased run() time
#      (compared to one container per kata)
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

class DockerAvatarVolumeRunner

  include DockerRunnerVolumeMixIn

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # kata
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def kata_exists?(_image_name, kata_id)
    assert_valid_id(kata_id)
    volume_exists?(kata_volume_name(kata_id))
  end

  def new_kata(_image_name, kata_id)
    refute_kata_exists(kata_id)
    create_volume(kata_volume_name(kata_id))
  end

  def old_kata(_image_name, kata_id)
    assert_kata_exists(kata_id)
    remove_volume(kata_volume_name(kata_id))
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # avatar
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def avatar_exists?(_image_name, kata_id, avatar_name)
    assert_valid_id(kata_id)
    assert_kata_exists(kata_id)
    assert_valid_name(avatar_name)
    volume_exists?(avatar_volume_name(kata_id, avatar_name))
  end

  def new_avatar(image_name, kata_id, avatar_name, starting_files)
    assert_valid_id(kata_id)
    assert_kata_exists(kata_id)
    refute_avatar_exists(kata_id, avatar_name)
    volume_name = avatar_volume_name(kata_id, avatar_name)
    create_volume(volume_name)
    volume_root = sandbox_path(avatar_name)
    cid = create_container(image_name, kata_id, avatar_name, volume_name, volume_root)
    begin
      chown_sandbox(cid, avatar_name)
      write_files(cid, avatar_name, starting_files)
    ensure
      remove_container(cid)
    end
  end

  def old_avatar(_image_name, kata_id, avatar_name)
    assert_kata_exists(kata_id)
    assert_avatar_exists(kata_id, avatar_name)
    remove_volume(avatar_volume_name(kata_id, avatar_name))
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # run
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Copes with infinite loops (eg) in the avatar's
  # code/tests by removing the container - which kills
  # all processes running inside the container.
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def run(image_name, kata_id, avatar_name, deleted_filenames, changed_files, max_seconds)
    assert_valid_id(kata_id)
    assert_kata_exists(kata_id)
    assert_avatar_exists(kata_id, avatar_name)
    volume_name = avatar_volume_name(kata_id, avatar_name)
    volume_root = sandbox_path(avatar_name)
    cid = create_container(image_name, kata_id, avatar_name, volume_name, volume_root)
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

  def kata_volume_name(kata_id)
    'cyber_dojo_avatar_volume_runner_kata_' + kata_id
  end

  def avatar_volume_name(kata_id, avatar_name)
    'cyber_dojo_avatar_volume_runner_avatar_' + kata_id + '_' + avatar_name
  end

end
