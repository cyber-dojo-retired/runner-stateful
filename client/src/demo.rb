require 'sinatra'
require 'sinatra/base'

require_relative './runner_post_adapter'

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
    json = nil
    html = '<div style="font-size:0.5em">'

    duration = timed { json = runner.new_kata(kata_id, image_name) }
    html += pre('new_kata', duration, json)

    duration = timed { json = runner.new_avatar(image_name, kata_id, avatar_name, files) }
    html += pre('new_avatar', duration, json)

    duration = timed { json = run({}) }
    html += pre('run', duration, json, 'Red')

    syntax_error = { 'hiker.c' => 'sdsdsdsd' }
    duration = timed { json = run(syntax_error) }
    html += pre('run', duration, json, 'Yellow')

    tests_run_and_pass = { 'hiker.c' => hiker_c.sub('6 * 9', '6 * 7') }
    duration = timed { json = run(tests_run_and_pass) }
    html += pre('run', duration, json, 'Lime')

    times_out = { 'hiker.c' => hiker_c.sub('return', "for(;;);\n    return") }
    duration = timed { json = run(times_out, 3) }
    html += pre('run', duration, json, 'LightGray')

    duration = timed { json = runner.old_avatar(kata_id, avatar_name) }
    html += pre('old_avatar', duration, json)

    duration = timed { json = runner.old_kata(kata_id) }
    html += pre('old_kata', duration, json)

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
    RunnerPostAdapter.new
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

  def pre(name, duration, json, colour = 'white')
    border = 'border:1px solid black'
    padding = 'padding:10px'
    background = "background:#{colour}"
    "<pre>/#{name}(#{duration}s)</pre>" +
    "<pre style='#{border};#{padding};#{background}'>" +
    "#{JSON.pretty_unparse(json)}" +
    '</pre>'
  end

end


