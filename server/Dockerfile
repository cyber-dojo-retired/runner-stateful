FROM cyberdojo/docker
MAINTAINER Jon Jagger <jon@jaggersoft.com>

COPY . /app

ARG PORT
EXPOSE ${PORT}

ENV PORT=${PORT}
CMD [ "./up.sh" ]
