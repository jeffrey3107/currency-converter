FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install gunicorn

COPY . .

EXPOSE 5000

ENV ACCESS_KEY=d26a7d253982c47715e2e8ba2216a62a

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
