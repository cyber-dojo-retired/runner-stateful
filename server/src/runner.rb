
def runner_class
  env_var = ENV['CYBER_DOJO_RUNNER_CLASS']
  if env_var != '' && !env_var.nil?
    env_var
  else
    'DockerAvatarVolumeRunner'
  end
end

require_relative 'snake_caser'
require_relative SnakeCaser::snake_cased(runner_class)

module Runner # mix-in

  def runner
    @runner ||= Object.const_get(runner_class).new(self, image_name, kata_id)
  end

end
