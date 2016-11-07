require_relative './runner_test_base'

class DockerRunnerKataTest < RunnerTestBase

  def self.hex_prefix; 'FB0D4'; end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'CC8',
  'when image_name is valid and has not been pulled',
  'then new_kata(kata_id, image_name) pulls it and succeeds' do
    @image_name = 'busybox'
    exec("docker rmi #{@image_name}", logging = false)
    refute docker_pulled?(@image_name)
    _,_,status = new_kata
    begin
      assert status
      assert docker_pulled?(@image_name)
    ensure
      old_kata
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '5E7',
  'when image_name is valid has been pulled',
  'then new_kata(kata_id, image_name) succeeds' do
    @image_name = 'busybox'
    exec("docker pull #{@image_name}", logging = false)
    assert docker_pulled?(@image_name)
    _,_,status = new_kata
    begin
      assert status
      assert docker_pulled?(@image_name)
    ensure
      old_kata
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'AED',
  'when image_name is invalid then new_kata(kata_id, image_name) fails with not-found' do
    bad_image_name = '123/123'
    runner.logging_off
    raised = assert_raises(DockerRunnerError) { runner.new_kata(kata_id, bad_image_name) }
    refute_equal 0, raised.status
    assert_equal [
      "Using default tag: latest",
      "Pulling repository docker.io/#{bad_image_name}"
    ].join("\n"), raised.stdout
    assert_equal "Error: image #{bad_image_name}:latest not found", raised.stderr
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  test 'FA0',
  "old_kata removes all avatar's volumes" do
    @image_name = 'busybox'
    new_kata
    expected = []
    ['lion','salmon'].each do |avatar_name|
      runner.new_avatar(kata_id, avatar_name)
      expected << volume_name(avatar_name)
    end
    assert_equal expected, volume_names.sort
    old_kata
    assert_equal [], volume_names.sort
  end

  private

  def docker_pulled?(image_name)
    image_names.include?(image_name)
  end

  def image_names
    stdout,_ = assert_exec('docker images')
    lines = stdout.split("\n")
    lines.shift # lose headings [REPOSITORY TAG IMAGE ID CREATED SIZE]
    lines.collect { |line| line.split[0] }
  end

  def volume_names
    stdout,_ = assert_exec("docker volume ls --quiet --filter 'name=#{volume_name}'")
    stdout.split("\n")
  end

  def volume_name(avatar_name = nil)
    parts = [ 'cyber', 'dojo', kata_id ]
    parts << avatar_name unless avatar_name.nil?
    parts.join('_')
  end

end

