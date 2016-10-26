FROM cyberdojo/runner_base
MAINTAINER Jon Jagger <jon@jaggersoft.com>

ARG app_dir
COPY . ${app_dir}
EXPOSE 4558
CMD [ "foreman", "start", "-d", "/app" ]
