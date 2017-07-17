
# I had envisaged using the image_name to decide which stateful runner to use.
# Now decided against that (retaining the same image_name, with no version tag,
# is the key strategy for backwards compatibility).
# Better and simpler to use an image label.

def runner_class_name
  class_name = 'SharedVolumeRunner'   # default
  # dynamically load Ruby file so coverage stats
  # don't include the runner that's not being used.
  autoload(:SharedVolumeRunner, '/app/src/shared_volume_runner.rb') if class_name == 'SharedVolumeRunner'
  class_name
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

module Runner # mix-in

  def runner
    new_runner(image_name, kata_id)
  end

  def new_runner(image_name, kata_id)
    class_name = runner_class_name
    Object.const_get(class_name).new(self, image_name, kata_id)
  end

end
