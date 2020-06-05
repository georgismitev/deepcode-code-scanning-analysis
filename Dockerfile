FROM python:3.7.3-alpine

RUN apk add bash jq

RUN apk add --no-cache --virtual .build-deps g++ libffi-dev \
 && pip install --upgrade pip \
 && pip install deepcode \
 && apk del .build-deps

COPY entrypoint.sh /deepcode/entrypoint.sh
COPY deepcode_to_sarif.py /deepcode/deepcode_to_sarif.py

CMD [ "bash", "/deepcode/entrypoint.sh" ]
