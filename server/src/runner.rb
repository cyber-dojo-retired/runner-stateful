require_relative 'snake_caser'

def default_runner_name
  'DockerKataVolumeRunner'
end

def env_require_runner(name)
  env = ENV['CYBER_DOJO_RUNNER_CLASS']
  if env == name || (env.nil? && name == default_runner_name)
    require_relative SnakeCaser::snake_cased(name)
  end
end

env_require_runner 'DockerAvatarVolumeRunner'
env_require_runner 'DockerKataVolumeRunner'
env_require_runner 'DockerKataContainerRunner'

def runner_class
  env_var = ENV['CYBER_DOJO_RUNNER_CLASS']
  if env_var != '' && !env_var.nil?
    env_var
  else
    default_runner_name
  end
end

module Runner # mix-in

  def runner
    @runner ||= Object.const_get(runner_class).new(self, image_name, kata_id)
  end

end
