.DEFAULT_GOAL := docker
IMAGE := vpro/openshift-helm:main

help:     ## Show this help.
	@sed -n 's/^##//p' $(MAKEFILE_LIST)
	@grep -E '^[/%a-zA-Z._-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

docker: ## build image locally
	docker build -t $(IMAGE) .

explore:  ## look around
	docker run -it --entrypoint /bin/bash $(IMAGE)