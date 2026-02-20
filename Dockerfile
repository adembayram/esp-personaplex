ARG BASE_IMAGE="nvcr.io/nvidia/cuda"
ARG BASE_IMAGE_TAG="12.4.1-runtime-ubuntu22.04"

FROM ${BASE_IMAGE}:${BASE_IMAGE_TAG} AS base

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    pkg-config \
    libopus-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app/moshi/

COPY moshi/ /app/moshi/
RUN uv venv /app/moshi/.venv --python 3.12
RUN uv sync

RUN mkdir -p /app/ssl

# RunPod exposes services on specific ports; 8998 is the default for PersonaPlex
EXPOSE 8998

# Health check for RunPod monitoring
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:8998/ || exit 1

ENTRYPOINT []

# Run on 0.0.0.0 to be accessible from RunPod proxy, with SSL and static=none (API only mode)
CMD ["/app/moshi/.venv/bin/python", "-m", "moshi.server", \
     "--host", "0.0.0.0", \
     "--port", "8998", \
     "--ssl", "/app/ssl", \
     "--static", "none"]
