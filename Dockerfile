FROM python:3.11.9-slim-bookworm



RUN apt-get update && apt-get upgrade -y && apt-get clean

WORKDIR /application

COPY requirements.txt .
# Force upgrade Python packages to match Trivy fixed versions
RUN pip install --upgrade --no-cache-dir -r requirements.txt

# Copy application code last (cache efficiency)
COPY . .

EXPOSE 5000
CMD ["python", "app.py"]
