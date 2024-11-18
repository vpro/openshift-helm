.DEFAULT_GOAL := docker
TAG := $(shell git symbolic-ref -q --short HEAD || git describe --tags --exact-match)
IMAGE := vpro/openshift-helm:$(TAG)
MMIMAGE:=mmbase/openshift-helm:$(TAG)

help:     ## Show this help.
	@sed -n 's/^##//p' $(MAKEFILE_LIST)
	@grep -E '^[/%a-zA-Z._-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

docker: ## build image locally
	docker build --no-cache -t $(IMAGE) .

explore:  ## look around
	docker run -it  $(IMAGE)



# lets try to push a verison in docker.io, just to try out whether we then can  in gitlab'
# 'Enable the Dependency Proxy to cache container images from Docker Hub and automatically clear the cache.'
mmdocker: ## build image locally for upload in docker.io/mmbase
	docker buildx  build --platform linux/amd64  -t $(MMIMAGE) .


mmpush:
	docker image push $(MMIMAGE)