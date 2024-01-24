FROM python:3.10 AS export
RUN pip install --no-cache-dir pipenv
COPY Pipfile Pipfile.lock ./
RUN pipenv requirements --dev > /requirements-dev.lock \
    && pipenv requirements > /requirements.lock

FROM python:3.10 AS builder-dev
COPY --from=export /requirements-dev.lock /
RUN pip install --no-cache-dir -r /requirements-dev.lock

FROM python:3.10 AS builder
COPY --from=export /requirements.lock /
RUN pip install --no-cache-dir -r /requirements.lock

FROM python:3.10-slim AS base
WORKDIR /working

RUN apt update \
    && apt upgrade -y

COPY hello.sh /
CMD ["/bin/bash", "/hello.sh"]

FROM base AS dev
COPY --from=builder-dev /usr/local/lib/python3.10/site-packages \
    /usr/local/lib/python3.10/site-packages
COPY --from=builder-dev /usr/local/bin /usr/local/bin

FROM base AS prod
COPY --from=builder /usr/local/lib/python3.10/site-packages \
    /usr/local/lib/python3.10/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
