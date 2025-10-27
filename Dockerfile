<<<<<<< HEAD
FROM  python:3.11.8-alpine3.18
=======
FROM python:3.12.0b3-alpine3.18
>>>>>>> ed246b91854b0a41a65e3535bf5ce10fe83fa695
COPY . /application
WORKDIR /application
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
EXPOSE 5000
CMD ["python", "app.py"]