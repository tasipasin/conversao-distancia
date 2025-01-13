# using ubuntu LTS version
FROM ubuntu:20.04 AS builder-image

# avoid stuck build due to user prompt
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install --no-install-recommends -y python3.9 python3.9-dev python3.9-venv python3-pip python3-wheel build-essential && \
	apt-get clean && rm -rf /var/lib/apt/lists/* 

# create and activate virtual environment
# using final folder name to avoid path issues with packages
RUN python3.9 -m venv /home/KubeDev/venv
ENV PATH="/home/KubeDev/venv/bin:$PATH"

# install python project requirements
COPY requirements.txt .
RUN pip3 install --upgrade gevent
RUN pip3 install --no-cache-dir wheel
RUN pip3 install --no-cache-dir -r requirements.txt

FROM ubuntu:20.04 AS runner-image
RUN apt-get update && apt-get install --no-install-recommends -y python3.9 python3-venv && \
	apt-get clean && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home KubeDev
COPY --from=builder-image /home/KubeDev/venv /home/KubeDev/venv

USER KubeDev
RUN mkdir /home/KubeDev/conversor-distancia
WORKDIR /home/KubeDev/conversor-distancia
COPY . .

EXPOSE 5000

# make sure all messages always reach console
ENV PYTHONUNBUFFERED=1

# activate virtual environment
ENV VIRTUAL_ENV=/home/KubeDev/venv
ENV PATH="/home/KubeDev/venv/bin:$PATH"

# /dev/shm is mapped to shared memory and should be used for gunicorn heartbeat
# this will improve performance and avoid random freezes
CMD ["gunicorn","-b", "0.0.0.0:5000", "-w", "4", "-k", "gevent", "--worker-tmp-dir", "/dev/shm", "app:app"]