
FROM python:3.11.8-alpine3.18
RUN apk upgrade --no-cache
COPY . /application
WORKDIR /application
COPY requirements.txt .
RUN pip install --upgrade --no-cache-dir -r requirements.txt
EXPOSE 5000
CMD ["python", "app.py"]