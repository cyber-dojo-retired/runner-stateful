
[![Build Status](https://travis-ci.org/cyber-dojo/runner.svg?branch=master)](https://travis-ci.org/cyber-dojo/runner)

<img src="https://raw.githubusercontent.com/cyber-dojo/nginx/master/images/home_page_logo.png" alt="cyber-dojo yin/yang logo" width="50px" height="50px"/>

Work in progress.

```
./build.sh
```
Rebuilds the docker runner-client and runner-server images.


```
./up.sh
```
Brings up the runner-client and runner-server containers.
The runner-client runs on port 4558.
The runner-server run on port 4557.


```
./demo.sh
```
The runner-client calls each of the runner-server's micro-service methods
once and displays their json results.
If the runner-client's IP address is 192.168.99.100 then put
192.168.99.100:4558 into your browser to see the output.

```
./test.sh
```
Runs the runner-server's tests inside the runner-server container.
