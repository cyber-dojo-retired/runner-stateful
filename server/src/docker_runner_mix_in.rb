
module DockerRunnerMixIn

  attr_reader :parent

  def pulled?(image_name)
    image_names.include?(image_name)
  end

  def pull(image_name)
    assert_exec("docker pull #{image_name}")
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def user_id(avatar_name)
    assert_valid_name(avatar_name)
    40000 + all_avatars_names.index(avatar_name)
  end

  def home_path(avatar_name)
    "/home/#{avatar_name}"
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def group
    'cyber-dojo'
  end

  def gid
    5000
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def sandbox_path(avatar_name)
    assert_valid_name(avatar_name)
    "#{sandboxes_root}/#{avatar_name}"
  end

  module_function # = = = = = = = = = = = = = = = =

end

