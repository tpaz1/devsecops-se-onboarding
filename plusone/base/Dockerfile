FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Copy dependencies
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir --index-url=https://{REPO-USER}:{REPO-PASS}@setompaz.jfrog.io/artifactory/api/pypi/se-pypi/simple -r requirements.txt

CMD ["sh"]