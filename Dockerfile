FROM python:3.7.3-alpine

RUN apk add bash jq

RUN apk add --no-cache --virtual .build-deps g++ libffi-dev \
 && pip install --upgrade pip \
 && pip install deepcode \
 && apk del .build-deps

COPY dc/ /dc/

RUN adduser -u 2004 -D docker
RUN chown -R docker:docker /dc

CMD [ "bash", "/dc/entrypoint.sh" ]
