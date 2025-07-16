# ----------  Dockerfile  ----------
FROM python:3.8-slim

# Prevent interactive tz-data prompts, keep the image tiny
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /app

# ---------- 1. install Python libs with apt ----------
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        python3-flask \
        gunicorn \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# ---------- 2. copy application code ----------
COPY server.py .

# ---------- 3. drop privileges ----------
RUN useradd --create-home --shell /usr/sbin/nologin statususer
USER statususer

EXPOSE 8000
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "server:app"]
