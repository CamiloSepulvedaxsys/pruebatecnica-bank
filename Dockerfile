# ---------- Stage 1: Build ----------
FROM python:3.12-slim AS builder

WORKDIR /app

COPY app/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---------- Stage 2: Runtime ----------
FROM python:3.12-slim

LABEL maintainer="camilo.sepulveda"
LABEL description="Flask sample app - Prueba Técnica Banco"

RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

WORKDIR /app

COPY --from=builder /install /usr/local
COPY app/ .

USER appuser

ENV FLASK_HOST=0.0.0.0
ENV FLASK_PORT=8000

EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "app:app"]
