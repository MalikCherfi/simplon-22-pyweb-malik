FROM python:3.14
WORKDIR /app

# Install the application dependencies
COPY requirements.txt ./
COPY pylock.toml ./
RUN pip install -r requirements.txt

COPY . /app

CMD ["python3", "app.py"]
EXPOSE 8000