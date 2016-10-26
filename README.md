
[![Build Status](https://travis-ci.org/cyber-dojo/runner.svg?branch=master)](https://travis-ci.org/cyber-dojo/runner)

<img src="https://raw.githubusercontent.com/cyber-dojo/nginx/master/images/home_page_logo.png" alt="cyber-dojo yin/yang logo" width="50px" height="50px"/>

# repo for **cyberdojo/runner** docker image

## API

- pulled?(image_name)
  * eg image_name = 'cyberdojofoundation/gcc_assert'
  * { status:true,  output:unspecified }   pulled already
  * { status:false, output:unspecified }   not pulled already

- pull(image_name)
  * eg image_name = 'cyberdojofoundation/gcc_assert'
  * { status:true,  output:unspecified }   pull succeeded

- hello_avatar(kata_id, avatar_name)
  * eg kata_id = '15B9AD6C42'
  * eg avatar_name = 'salmon'
  * { status:true,  output:unspecified }   succeeded

- goodbye_avatar(kata_id, avatar_name)
  * eg kata_id = '15B9AD6C42'
  * eg avatar_name = 'salmon'
  * { status:true,  output:unspecified }   succeeded

- run(image_name, kata_id, avatar_name, max_seconds, deleted_filenames, changed_files)
  * eg image_name = 'cyberdojofoundation/gcc_assert'
  * eg kata_id = '15B9AD6C42'
  * eg avatar_name = 'salmon'
  * eg max_seconds = '10'
  * eg deleted_filenames = [ filename, ... ]
  * eg changed_files = { filename => content, ... }
  * { status:true,   output:output }       succeeded
  * { status:false,  output:'' }           timed-out-and-killed

- if something unexpected goes wrong on the server all methods return
  * { status:error, output:msg }           something went wrong

## rebuild the runner-client and runner-server images
```
$ ./build.sh
```

## bring up a runner-client and runner-server container

```
$ ./up.sh
```

## run the runner-server's tests inside a runner-server container
```
$ ./test.sh
```

## run a runner-client demo
```
./demo.sh
```
Runs inside the runner-client container.
Calls each of the runner-server's micro-service methods
once and displays their json results.
If the runner-client's IP address is 192.168.99.100 then put
192.168.99.100:4558 into your browser to see the output.

