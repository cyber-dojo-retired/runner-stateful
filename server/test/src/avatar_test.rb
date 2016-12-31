require_relative 'test_base'

class AvatarTest < TestBase

  def self.hex_prefix; '20A7A'; end

  def hex_setup
    @image_name = 'cyberdojofoundation/gcc_assert'
    new_kata
  end

  def hex_teardown
    old_kata
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # positive test case
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '75E',
  "before new_avatar it's sandbox does not exist",
  "after new_avatar it's sandbox does exist" do
    refute avatar_exists?('lion')
    new_avatar({ avatar_name:'lion' })
    assert avatar_exists?('lion')
    old_avatar({ avatar_name:'lion' })
  end

  def avatar_exists?(avatar_name)
    sandbox = runner.sandbox_path(avatar_name)
    cid = create_container
    begin
      cmd = "docker exec #{cid} sh -c '[ -d #{sandbox} ]'"
      _stdout,_stderr,status = shell.exec(cmd, logging = false)
      status == success
    ensure
      rm_container(cid)
    end
  end

  def create_container
    args = [
      '--detach',
      '--interactive',
      '--net=none',
      '--user=root',
      "--volume=#{volume_name}:/sandboxes:rw"
    ].join(space)
    cid = assert_exec("docker run #{args} #{@image_name} sh")[0].strip
  end

  def rm_container(cid)
    assert_exec("docker rm --force #{cid}")
  end

  def volume_name; [ 'cyber', 'dojo', kata_id ].join('_'); end
  def space; ' '; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # negative tests cases: new_avatar
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'B20',
  'new_avatar with an invalid kata_id raises' do
    assert_method_raises(:new_avatar, invalid_kata_ids, 'salmon', 'kata_id:invalid')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '7C4',
  'new_avatar with non-existent kata_id raises' do
    kata_id = '42CF187311'
    assert_method_raises(:new_avatar, kata_id, 'salmon', 'kata_id:!exists')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '35D',
  'new_avatar with existing kata_id but invalid avatar_name raises' do
    assert_method_raises(:new_avatar, kata_id, invalid_avatar_names, 'avatar_name:invalid')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '119',
  'new_avatar with existing kata_id but avatar_name that already exists raises' do
    new_avatar({ avatar_name:'salmon' })
    assert_method_raises(:new_avatar, kata_id, 'salmon', 'avatar_name:exists')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -
  # negative test cases: old_avatar
  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '2A8',
  'old_avatar with invalid kata_id raises' do
    assert_method_raises(:old_avatar, invalid_kata_ids, 'salmon', 'kata_id:invalid')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'E35',
  'old_avatar with non-existent kata_id raises' do
    kata_id = '92BB3FE5B6'
    assert_method_raises(:old_avatar, kata_id, 'salmon', 'kata_id:!exists')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'E5D',
  'old_avatar with existing kata_id but invalid avatar_name raises' do
    assert_method_raises(:old_avatar, kata_id, invalid_avatar_names, 'avatar_name:invalid')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'D6F',
  'old_avatar with existing kata_id but avatar_name that does not exist raises' do
    assert_method_raises(:old_avatar, kata_id, 'salmon', 'avatar_name:!exists')
  end

  private

  def assert_method_raises(method, kata_ids, avatar_names, message)
    [*kata_ids].each do |kata_id|
      [*avatar_names].each do |avatar_name|
        error = assert_raises(ArgumentError) {
          self.send(method, {
                kata_id:kata_id,
            avatar_name:avatar_name
          })
        }
      assert_equal message, error.message
      end
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def invalid_avatar_names
    [
      nil,
      Object.new,
      [],
      '',
      'scissors'
    ]
  end

end
