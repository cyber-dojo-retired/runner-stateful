require_relative 'test_base'

class RessurectionTest < TestBase

  def self.hex_prefix
    '7B4'
  end

  # - - - - - - - - - - - - - - - - -

  test 'F5E', %w(
  when collector collects kata's volume
  then runner ressurects it and the avatar ) do
    in_kata {
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
    [ name_prefix, id_sha ].join('_')
  end

  def name_prefix
    'test_run__runner_stateful_'
  end

  def id_sha
    Digest::SHA1.hexdigest(id)[0..11]
  end

end
