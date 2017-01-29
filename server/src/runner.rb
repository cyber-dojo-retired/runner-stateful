def runner_class; ENV['CYBER_DOJO_RUNNER_CLASS']; end

require_relative 'snake_caser'
require_relative SnakeCaser::snake_cased(runner_class)

module Runner # mix-in

  def runner(the_image_name = image_name, the_kata_id = kata_id)
    @runner ||= Object.const_get(runner_class).new(self, the_image_name, the_kata_id)
  end

end
