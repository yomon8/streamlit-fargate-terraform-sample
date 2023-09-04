FROM python:3.10.13-slim-bullseye

ENV APP_ROOT /app
RUN mkdir -p ${APP_ROOT}
WORKDIR ${APP_ROOT}

RUN pip install poetry
RUN poetry config virtualenvs.create false
COPY pyproject.toml ${APP_ROOT}
COPY poetry.lock ${APP_ROOT}
RUN poetry install --only main --no-root

COPY ./.streamlit ${APP_ROOT}/.streamlit
COPY ./app ${APP_ROOT}

ENTRYPOINT ["streamlit","run","top.py","--"]