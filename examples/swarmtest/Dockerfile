FROM python:alpine
ADD . /code
WORKDIR /code
RUN pip install \
  flask \
  redis
CMD ["python", "app.py"]
