# Stage 1: build dependencies
FROM python:3.12-slim AS builder
WORKDIR /install
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: minimal runtime
FROM python:3.12-slim
RUN useradd --create-home appuser
WORKDIR /app
COPY --from=builder /install /usr/local
COPY app.py .
RUN mkdir -p /app/data && chown -R appuser:appuser /app

USER appuser
EXPOSE 8000
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "app:app"]
