FROM python:3.7.0-slim-stretch
MAINTAINER TS201 <TS201@example.com>

RUN apt-get update && apt-get -y install procps vim python3-dev
RUN mkdir -p /etc/supervisor /home/service/logs
     
WORKDIR /home/service 
COPY service /home/service
RUN pip install -r requirements.txt
CMD ["python","/home/service/main.py"]
