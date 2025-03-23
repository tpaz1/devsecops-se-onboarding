FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Copy dependencies
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir --index-url=https://{REPO-USER}:{REPO-PASS}@setompaz.jfrog.io/artifactory/api/pypi/se-pypi/simple -r requirements.txt

# Copy application
COPY app.py .

# Expose port
EXPOSE 5000

# Start the server
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "5000"]
