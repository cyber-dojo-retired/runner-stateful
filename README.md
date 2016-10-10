
[![Build Status](https://travis-ci.org/cyber-dojo/runner.svg?branch=master)](https://travis-ci.org/cyber-dojo/runner)

<img src="https://raw.githubusercontent.com/cyber-dojo/nginx/master/images/home_page_logo.png" alt="cyber-dojo yin/yang logo" width="50px" height="50px"/>

Work in progress.

runner_server still needs docker-in-docker image, sudo, docker-runner user etc.


```
./demo.sh
```

Creates two docker images; a runner-client and a runner-server (both using sinatra).
The runner-client sends a set of files (in a json body) to the runner-server and the
runner-server return the run output. The runner-client runs on port 4558 and the runner-server
on port 4557. If the runner-client's IP address is 192.168.99.100 then put
192.168.99.100:4558 into your browser to see the output.

```
./test.sh
```

Rebuilds the images and runs the tests inside the runner server/client containers

