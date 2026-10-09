FROM python:3.11-slim

WORKDIR /app

# opencv/ultralytics need these system libs at runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/ .
COPY modules/ /modules/

# Run as UID 1000 (Hugging Face Spaces runs containers as 1000; this is also
# safer on any other host). The app writes previews/uploads to /app/tmp and
# ultralytics writes its settings under $HOME, so both must be writable.
RUN useradd -m -u 1000 user \
    && mkdir -p /app/tmp \
    && chown -R 1000:1000 /app/tmp
ENV HOME=/home/user
USER 1000

EXPOSE 8002

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8002"]
