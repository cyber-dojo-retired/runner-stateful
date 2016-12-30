require_relative 'runner_test_base'
require_relative 'mock_sheller'

class DockerRunnerKataTest < RunnerTestBase

  def self.hex_prefix; 'FB0D4'; end

  def hex_setup; @image_name = 'cyberdojofoundation/gcc_assert'; end

  test 'D7B',
  'new_kata with an invalid kata_id raises' do
    invalid_ids = [
      nil,          # not string
      Object.new,   # not string
      [],           # not string
      '',           # not 10 chars
      '123456789',  # not 10 chars
      '123456789AB',# not 10 chars
      '0123456789G' # not 10 hex-chars
    ]
    invalid_ids.each do |invalid_id|
      error = assert_raises {
        new_kata({ kata_id:invalid_id })
      }
      assert error.message.start_with? 'kata_id'
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'DBC',
  'before new_kata volume does not exist,',
  'after new_kata it does,',
  'after old_kata it does not' do
    refute volume_exists?
    new_kata
    assert volume_exists?
    old_kata
    refute volume_exists?
  end

  private

  def volume_exists?
    cmd = [
      'docker volume ls',
      '--quiet',
      "--filter 'name=#{volume_name}'"
    ].join(space)
    stdout,_ = assert_exec(cmd)
    stdout.strip == volume_name
  end

  def volume_name; [ 'cyber', 'dojo', kata_id ].join('_'); end
  def space; ' '; end

end

