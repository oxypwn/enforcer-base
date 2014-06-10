.PHONY: all build binary default db run clean cleandb
BINDDIR := bundles
GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
DOCKER_IMAGE := enforcer$(if $(GIT_BRANCH),:$(GIT_BRANCH))
DOCKER_MOUNT := $(if $(BINDDIR),-v "$(CURDIR)/$(BINDDIR):/go/src/github.com/appstash/enforcer/$(BINDDIR)")

DOCKER_RUN_DOCKER := docker run --rm -it --privileged -e TESTFLAGS $(DOCKER_MOUNT) "$(DOCKER_IMAGE)"

default: binary

all: build
	$(DOCKER_RUN_DOCKER) hack/make.sh

binary: build
	$(DOCKER_RUN_DOCKER)  hack/make.sh binary

content:
	$(DOCKER_RUN_DOCKER) hack/make.sh content
ubuntu: binary
	$(DOCKER_RUN_DOCKER) hack/make.sh ubuntu
db:
	docker run -d -t -p 28015:28015 -p 8081:8080 -name rethinkdb crosbymichael/rethinkdb --bind all
cross: build
	$(DOCKER_RUN_DOCKER) hack/make.sh binary cross
gox: build
	$(DOCKER_RUN_DOCKER) hack/make.sh gox
shell: build
	$(DOCKER_RUN_DOCKER) bash
container: build cleandb db
	$(DOCKER_RUN_DOCKER) -h enforcer --link rethinkdb:db --name enforcer -p 4321:4321 "$(DOCKER_IMAGE)" hack/run.sh
clean:
	docker rm $(docker ps -a -q) ;  docker rmi enforcer:master
cleandb:
	docker stop rethinkdb ; docker rm rethinkdb || true
logs:
	watch -d docker logs enforcer
build: bundles
	docker build --rm -t "$(DOCKER_IMAGE)" .
bundles:
	mkdir bundles
