require_relative 'test_base'

class RessurectionTest < TestBase

  def self.hex_prefix
    '7B48B'
  end

  # - - - - - - - - - - - - - - - - -

  test 'F5E', %w(
  when collector collects kata's volume
  then runner ressurects it and the avatar ) do
    in_kata_as('salmon') {
      remove_kata_volume
      run_cyber_dojo_sh
      assert_colour 'red'
    }
  end

  private

  def remove_kata_volume
    shell.assert("docker volume rm #{kata_volume_name}")
  end

  def kata_volume_name
    [ name_prefix, kata_id ].join('_')
  end

  def name_prefix
    'test_run__runner_stateful_'
  end

end
