FROM python:3.8-alpine AS build

RUN apk add --no-cache build-base linux-headers

RUN python3 -m venv /venv
ENV PATH=/venv/bin:$PATH

WORKDIR /app
COPY app/requirements.txt .

RUN pip install --no-cache-dir requests
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.8-alpine

ENV FLASK_ENV=production
ENV FLASK_APP=run.py
ENV FLASK_RUN_HOST=0.0.0.0
ENV FLASK_RUN_PORT=80

COPY --from=build /venv /venv
ENV PATH=/venv/bin:$PATH

WORKDIR /app
COPY app ./

HEALTHCHECK --interval=12s --timeout=12s CMD python -c "import requests; requests.get('http://localhost:8080', timeout=2)"

CMD [ "python3", "-m" , "flask", "run"]