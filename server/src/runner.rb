
def runner_class_name
  #'DockerAvatarVolumeRunner'
  'DockerKataVolumeRunner'
  #'DockerKataContainerRunner' # some tests are failing
end

require_relative 'snake_caser'
require_relative SnakeCaser::snake_cased(runner_class_name)

module Runner # mix-in

  def runner
    Object.const_get(runner_class_name).new(self, image_name, kata_id)
  end

end
