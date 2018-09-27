FROM  cyberdojo/docker-base
LABEL maintainer=jon@jaggersoft.com

ARG HOME=/app
COPY . ${HOME}

ARG SHA
RUN echo ${SHA} > ${HOME}/sha.txt

EXPOSE 4557
CMD [ "./up.sh" ]
