
module DockerRunnerContainerMixIn

  module_function # = = = = = = = = = = = = = = = =

  def alpine_add_group_cmd
    "addgroup -g #{gid} #{group}"
  end

  def ubuntu_add_group_cmd
    "addgroup --gid #{gid} #{group}"
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def fail_kata_id(message)
    fail bad_argument("kata_id:#{message}")
  end

  def fail_avatar_name(message)
    fail bad_argument("avatar_name:#{message}")
  end

  def fail_command(message)
    fail bad_argument("command:#{message}")
  end

  def bad_argument(message)
    ArgumentError.new(message)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - -

  def sandboxes_root; '/sandboxes'; end
  def success; shell.success; end
  def space; ' '; end

end

