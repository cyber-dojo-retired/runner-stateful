require_relative 'runner_service'
require 'sinatra'
require 'sinatra/base'

class Demo < Sinatra::Base

  get '/' do
    @html = ''
    in_kata {
      as_avatar {
        red; amber; green; time_out
      }
    }
    "<div style='font-size:0.5em'>#{@html}</div>"
  end

  private

  def red
    change = {}
    duration = timed { @sss = run(change) }
    @html += pre('run', duration, 'Red', @sss)
  end

  def amber
    change = { 'hiker.c' => 'sdsdsdsd' }
    duration = timed { @sss = run(change) }
    @html += pre('run', duration, 'Yellow', @sss)
  end

  def green
    change = { 'hiker.c' => hiker_c.sub('6 * 9', '6 * 7') }
    duration = timed { @sss = run(change) }
    @html += pre('run', duration, 'Lime', @sss)
  end

  def time_out
    change = { 'hiker.c' => hiker_c.sub('return', "for(;;);\n return") }
    duration = timed { @sss = run(change, 3) }
    @html += pre('run', duration, 'LightGray', @sss)
  end

  def in_kata
    duration = timed { runner.kata_new(image_name, kata_id) }
    @html += pre('kata_new', duration)
    begin
      yield
    ensure
      duration = timed { runner.kata_old(image_name, kata_id) }
      @html += pre('kata_old', duration)
    end
  end

  def as_avatar
    duration = timed { runner.avatar_new(image_name, kata_id, avatar_name, files) }
    @html += pre('avatar_new', duration)
    begin
      yield
    ensure
      duration = timed { runner.avatar_old(image_name, kata_id, avatar_name) }
      @html += pre('avatar_old', duration)
    end
  end

  def timed
    started = Time.now
    yield
    finished = Time.now
    '%.2f' % (finished - started)
  end

  def runner
    RunnerService.new
  end

  def run(files, max_seconds=10)
    deleted_filenames = []
    runner.run(image_name, kata_id, avatar_name, deleted_filenames, files, max_seconds)
  end

  def files
    {
      'hiker.c'       => hiker_c,
      'hiker.h'       => read('hiker.h'),
      'hiker.tests.c' => read('hiker.tests.c'),
      'cyber-dojo.sh' => read('cyber-dojo.sh'),
      'makefile'      => read('makefile')
    }
  end

  def hiker_c
    read('hiker.c')
  end

  def read(filename)
    IO.read("/app/test/start_files/gcc_assert/#{filename}")
  end

  def image_name
    'cyberdojofoundation/gcc_assert'
  end

  def kata_id
    'D4C8A65D61'
  end

  def avatar_name
    'lion'
  end

  def pre(name, duration, colour='white', sss=nil)
    border = 'border:1px solid black'
    padding = 'padding:10px'
    margin = 'margin-left:20px'
    background = "background:#{colour}"
    html = "<pre>/#{name}(#{duration}s)</pre>"
    unless sss == nil
      html += "<pre style='#{margin};#{border};#{padding};#{background}'>" +
              "#{JSON.pretty_unparse(sss)}" +
              '</pre>'
    end
    html
  end

end
