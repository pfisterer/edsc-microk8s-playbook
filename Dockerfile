FROM cytopia/ansible

RUN apk add --update \
	python3-dev \
	py3-setuptools \
	ca-certificates \
	gcc \
	libffi-dev \
	openssl-dev \
	musl-dev \
	linux-headers \
	openssh

RUN pip3 install --upgrade --no-cache-dir pip setuptools openstacksdk

RUN apk del gcc musl-dev linux-headers libffi-dev && rm -rf /var/cache/apk/*

RUN mkdir /app
WORKDIR /app

ADD . /app

VOLUME /root/.ssh/
VOLUME /data/

CMD ["ansible-playbook", "deploy.yaml"]