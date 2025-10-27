FROM python:3.11.8-alpine3.18

# Upgrade Alpine system packages first
RUN apk upgrade --no-cache

WORKDIR /application

COPY requirements.txt .
# Force upgrade Python packages to match Trivy fixed versions
RUN pip install --upgrade --no-cache-dir -r requirements.txt

# Copy application code last (cache efficiency)
COPY . .

EXPOSE 5000
CMD ["python", "app.py"]
