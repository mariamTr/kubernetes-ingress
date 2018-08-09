all: push

VERSION = 1.3.0
TAG = $(VERSION)
PREFIX = nginx/nginx-ingress

DOCKER_RUN = docker run --rm -v $(shell pwd):/go/src/github.com/nginxinc/kubernetes-ingress
DOCKER_BUILD_RUN = docker run --rm -v $(shell pwd):/go/src/github.com/nginxinc/kubernetes-ingress -w /go/src/github.com/nginxinc/kubernetes-ingress/cmd/nginx-ic/
GOLANG_CONTAINER = golang:1.10
DOCKERFILEPATH = build
DOCKERFILE = Dockerfile

BUILD_IN_CONTAINER = 1
PUSH_TO_GCR =
GENERATE_DEFAULT_CERT_AND_KEY =
DOCKER_BUILD_OPTIONS =

GIT_COMMIT=$(shell git rev-parse --short HEAD)

nginx-ingress:
ifeq ($(BUILD_IN_CONTAINER),1)
	$(DOCKER_BUILD_RUN) -e CGO_ENABLED=0 $(GOLANG_CONTAINER) go build -a -installsuffix cgo -ldflags "-w -X main.version=${VERSION} -X main.gitCommit=${GIT_COMMIT}" -o /go/src/github.com/nginxinc/kubernetes-ingress/nginx-ingress
else
	CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags "-w -X main.version=${VERSION} -X main.gitCommit=${GIT_COMMIT}" -o nginx-ingress
endif

test:
ifeq ($(BUILD_IN_CONTAINER),1)
	$(DOCKER_RUN) $(GOLANG_CONTAINER) go test ./...
else
	go test ./...
endif

certificate-and-key:
ifeq ($(GENERATE_DEFAULT_CERT_AND_KEY),1)
	./build/generate_default_cert_and_key.sh
endif

container: test nginx-ingress certificate-and-key
	cp $(DOCKERFILEPATH)/$(DOCKERFILE) .
	docker build $(DOCKER_BUILD_OPTIONS) -f $(DOCKERFILE) -t $(PREFIX):$(TAG) .

push: container
ifeq ($(PUSH_TO_GCR),1)
	gcloud docker -- push $(PREFIX):$(TAG)
else
	docker push $(PREFIX):$(TAG)
endif

clean:
	rm -f nginx-ingress
	rm $(DOCKERFILE)