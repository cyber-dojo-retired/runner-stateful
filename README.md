
[![Build Status](https://travis-ci.org/cyber-dojo/runner.svg?branch=master)](https://travis-ci.org/cyber-dojo/runner)

<img src="https://raw.githubusercontent.com/cyber-dojo/nginx/master/images/home_page_logo.png" alt="cyber-dojo yin/yang logo" width="50px" height="50px"/>

# cyberdojo/runner docker image

Work in progress. Not live yet.
A **cyberdojo/runner** docker container runs sinatra on port 4557.

## API

### pulled
- parameters
  * image_name, eg 'cyberdojofoundation/gcc_assert'
- returns
  * { "status":"true" , "output":unspecified } -> pulled already
  * { "status":"false", "output":unspecified } -> not pulled already

### pull
- parameters
  * image_name, eg 'cyberdojofoundation/gcc_assert'
- returns
  * { "status":"ok", "output":unspecified } -> pull succeeded

### hello
- parameters
  * kata_id, eg '15B9AD6C42'
  * avatar_name, eg 'salmon'
- returns
  * { "status":"ok", "output":unspecified } -> succeeded

### goodbye
- parameters
  * kata_id, eg '15B9AD6C42'
  * avatar_name, eg 'salmon'
- returns
  * { "status":"ok", "output":unspecified } -> succeeded

### execute
- parameters
  * image_name, eg 'cyberdojofoundation/gcc_assert'
  * kata_id, eg '15B9AD6C42'
  * avatar_name, eg 'salmon'
  * max_seconds, eg '10'
  * deleted_filenames, eg [ 'hiker.h', ... ]
  * changed_files, eg { 'fizz_buzz.h' => '#include', ... }
- returns
  * { "status":"0",   "output":output } -> succeeded
  * { "status":"137", "output":"" } -> did not complete in max_seconds

- if something unexpected goes wrong on the server all methods return
  * { status:error, output:msg } -> something went wrong

# build the docker images
Builds the runner-server image and an example runner-client image.
```
$ ./build.sh
```

# bring up the docker containers
Brings up a runner-server container and a runner-client container.

```
$ ./up.sh
```

# run the tests
Runs the runner-server's tests from inside a runner-server container
and then the runner-client's tests from inside the runner-client container.
```
$ ./test.sh
```

# run the demo
Runs inside the runner-client's container.
Calls each of the runner-server's micro-service methods
once and displays their json results and how long they took.
If the runner-client's IP address is 192.168.99.100 then put
192.168.99.100:4558 into your browser to see the output.
```
$ ./demo.sh
```
