require 'sinatra'
require 'sinatra/base'

require_relative './runner_service_adapter'

class Demo < Sinatra::Base

  get '/' do
    hiker_c = read('hiker.c')
    tests_run_but_fail = {
      'hiker.c'       => hiker_c,
      'hiker.h'       => read('hiker.h'),
      'hiker.tests.c' => read('hiker.tests.c'),
      'cyber-dojo.sh' => read('cyber-dojo.sh'),
      'makefile'      => read('makefile')
    }
    json = nil
    html = '<div style="font-size:0.5em">'

    duration = timed { json = runner.pulled?(image_name) }
    html += pre('pulled?', duration, json)

    duration = timed { json = runner.pull(image_name) }
    html += pre('pull', duration, json)

    duration = timed { json = runner.hello(kata_id, avatar_name) }
    html += pre('hello', duration, json)

    duration = timed { json = run(tests_run_but_fail) }
    html += pre('run', duration, json, 'red')

    syntax_error = { 'hiker.c' => 'sdsdsdsd' }
    duration = timed { json = run(syntax_error) }
    html += pre('run', duration, json, 'yellow')

    tests_run_and_pass = { 'hiker.c' => hiker_c.sub('6 * 9', '6 * 7') }
    duration = timed { json = run(tests_run_and_pass) }
    html += pre('run', duration, json, 'green')

    times_out = { 'hiker.c' => hiker_c.sub('return', 'for(;;); return') }
    duration = timed { json = run(times_out, 3) }
    html += pre('run', duration, json, 'gray')

    duration = timed { json = runner.goodbye(kata_id, avatar_name) }
    html += pre('goodbye', duration, json)

    html += '</div>'
  end

  private

  def image_name; 'cyberdojofoundation/gcc_assert'; end
  def kata_id; 'D4C8A65D61'; end
  def avatar_name; 'lion'; end

  def run(files, max_seconds = 10)
    deleted_filenames = []
    runner.run(image_name, kata_id, avatar_name, max_seconds, deleted_filenames, files)
  end

  def runner
    RunnerServiceAdapter.new
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


