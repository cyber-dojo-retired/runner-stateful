require_relative 'runner_service'
require 'sinatra'
require 'sinatra/base'

class Demo < Sinatra::Base

  get '/' do
    hiker_c = read('hiker.c')
    files = {
      'hiker.c'       => hiker_c,
      'hiker.h'       => read('hiker.h'),
      'hiker.tests.c' => read('hiker.tests.c'),
      'cyber-dojo.sh' => read('cyber-dojo.sh'),
      'makefile'      => read('makefile')
    }
    sss = nil
    html = '<div style="font-size:0.5em">'

    runner.new_kata(image_name, kata_id)
    runner.new_avatar(image_name, kata_id, avatar_name, files)
    duration = timed { sss = run({}) }
    html += pre('run', duration, sss, 'Red')

    syntax_error = { 'hiker.c' => 'sdsdsdsd' }
    duration = timed { sss = run(syntax_error) }
    html += pre('run', duration, sss, 'Yellow')

    tests_run_and_pass = { 'hiker.c' => hiker_c.sub('6 * 9', '6 * 7') }
    duration = timed { sss = run(tests_run_and_pass) }
    html += pre('run', duration, sss, 'Lime')

    times_out = { 'hiker.c' => hiker_c.sub('return', "for(;;);\n    return") }
    duration = timed { sss = run(times_out, 3) }
    html += pre('run', duration, sss, 'LightGray')

    runner.old_avatar(image_name, kata_id, avatar_name)
    runner.old_kata(image_name, kata_id)

    html += '</div>'
  end

  private

  def image_name; 'cyberdojofoundation/gcc_assert'; end
  def kata_id; 'D4C8A65D61'; end
  def avatar_name; 'lion'; end

  def run(files, max_seconds = 10)
    deleted_filenames = []
    runner.run(image_name, kata_id, avatar_name, deleted_filenames, files, max_seconds)
  end

  def runner
    RunnerService.new
  end

  def read(filename)
    IO.read("/app/start_files/gcc_assert/#{filename}")
  end

  def timed
    started = Time.now
    yield
    finished = Time.now
    '%.2f' % (finished - started)
  end

  def pre(name, duration, sss, colour = 'white')
    border = 'border:1px solid black'
    padding = 'padding:10px'
    background = "background:#{colour}"
    "<pre>/#{name}(#{duration}s)</pre>" +
    "<pre style='#{border};#{padding};#{background}'>" +
    "#{JSON.pretty_unparse(sss)}" +
    '</pre>'
  end

end


