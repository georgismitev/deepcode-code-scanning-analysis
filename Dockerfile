FROM python:3.7.3-alpine

ARG DEEPCODE_TOKEN=''
ENV DEEPCODE_TOKEN ${DEEPCODE_TOKEN}


# DEPENDENCIES #

RUN apk add bash jq

RUN apk add --no-cache --virtual .build-deps g++ libffi-dev \
 && pip install --upgrade pip \
 && pip install deepcode \
 && apk del .build-deps

# FILES AND USERS # 

COPY dc/ /dc/
RUN echo "{\"service_url\": \"https://www.deepcode.ai\", \"api_key\": \"$DEEPCODE_TOKEN\"}" > /dc/config.json

RUN adduser -u 2004 -D docker
RUN chown -R docker:docker /dc

CMD [ "bash", "/dc/entrypoint.sh" ]
