
[![Build Status](https://travis-ci.org/cyber-dojo/runner.svg?branch=master)](https://travis-ci.org/cyber-dojo/runner)

<img src="https://raw.githubusercontent.com/cyber-dojo/nginx/master/images/home_page_logo.png" alt="cyber-dojo yin/yang logo" width="50px" height="50px"/>

# repo for **cyberdojo/runner** docker image

## planned API

- if something unexpected goes wrong on the server all methods return
  * { status:error, output:msg }           something went wrong

- pulled?
  * { status:true,  output:unspecified }   pulled already
  * { status:false, output:unspecified }   not pulled already

- pull
  * { status:true,  output:unspecified }   pull succeeded

- hello_avatar
  * { status:true,  output:unspecified }   succeeded

- goodbye_avatar
  * { status:true,  output:unspecified }   succeeded

- run
  * { status:true,   output:output }       succeeded
  * { status:false,  output:'' }           timed-out-and-killed


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

## run a runner-client's demo
```
./demo.sh
```
Runs inside the runner-client container.
Calls each of the runner-server's micro-service methods
once and displays their json results.
If the runner-client's IP address is 192.168.99.100 then put
192.168.99.100:4558 into your browser to see the output.

