FROM cyberdojo/foreman
MAINTAINER Jon Jagger <jon@jaggersoft.com>

ARG APP_DIR
COPY . ${APP_DIR}
WORKDIR ${APP_DIR}

ARG PORT
ENV PORT=${PORT}
EXPOSE ${PORT}
ENTRYPOINT [ "foreman", "start" ]
