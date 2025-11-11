FROM tompazus.jfrog.io/docker-virtual/plusone-app-base:latest

# Copy application
COPY app.py .

# Expose port
EXPOSE 5000

# Start the server
CMD ["python", "-m", "uvicorn", "app:app", "--host", "0.0.0.0", "--port", "5000"]
