FROM cyberdojo/foreman
MAINTAINER Jon Jagger <jon@jaggersoft.com>

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# setup foreman port

ARG PORT
ENV PORT=${PORT}
EXPOSE ${PORT}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# install app

ARG APP_DIR
COPY . ${APP_DIR}
