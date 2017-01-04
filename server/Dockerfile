FROM cyberdojo/docker
MAINTAINER Jon Jagger <jon@jaggersoft.com>

RUN apk --update add tar

COPY . /app

ARG PORT
EXPOSE ${PORT}

ENV PORT=${PORT}
CMD [ "./up.sh" ]
