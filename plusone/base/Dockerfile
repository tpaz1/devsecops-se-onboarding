FROM tompazus.jfrog.io/docker-virtual/library/python:3.12-slim

# Set working directory
WORKDIR /app

# Use non-root user
RUN useradd -m appuser && chown -R appuser /app
USER appuser

# Copy and install dependencies securely
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir --index-url=https://{REPO-USER}:{REPO-PASS}@setompaz.jfrog.io/artifactory/api/pypi/se-pypi/simple -r requirements.txt

# Default command (can be overridden)
CMD ["sh"]