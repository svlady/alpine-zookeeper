REPO ?= svlady
NAME = $(REPO)/alpine-zookeeper
PKG_VERSION  ?= 3.4.13
TAG = $(PKG_VERSION)

build:
	docker build --build-arg PKG_VERSION=$(PKG_VERSION) -t $(NAME) .
	docker tag $(NAME) $(NAME):$(TAG)

release: build
	docker push $(NAME):$(TAG)

run: build
	docker run -it --rm --net=host --hostname=zk-0 --add-host=zk-0:127.0.0.1 $(NAME):$(TAG)

shell:
	docker run -it --rm --net=host --hostname=zk-0 --add-host=zk-0:127.0.0.1 --entrypoint=/bin/sh $(NAME):$(TAG)
