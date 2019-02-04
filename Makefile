REPO ?= svlady
NAME = $(REPO)/alpine-zookeeper
PKG_VERSION  ?= 3.5.4
TAG = $(PKG_VERSION)

build:
	docker build --build-arg PKG_VERSION=$(PKG_VERSION) -t $(NAME) .
	docker tag $(NAME) $(NAME):$(TAG)

release: build
	docker push $(NAME):$(TAG)

run: build
	docker run -it --rm --net=host $(NAME):$(TAG)

shell:
	docker run -it --rm --net=host --entrypoint=/bin/sh $(NAME):$(TAG)
