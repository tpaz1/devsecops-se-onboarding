FROM python:3.10-slim

# Copy application
COPY app.py .

# Expose port
EXPOSE 5000

# Start the server
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "5000"]
