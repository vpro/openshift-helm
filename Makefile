

docker:
	docker build -t vpro/openshift-helm:dev .

explore:
	docker run -it --entrypoint /bin/bash vpro/openshift-helm:dev