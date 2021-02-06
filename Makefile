include make.env

BUILD_DATE ?= $(shell date -u +%Y-%m-%dT%H%M%S%Z)

BUILD = --build-arg VERSION=$(VERSION) --build-arg CHECKSUM=$(CHECKSUM) --build-arg BUILD_DATE=$(BUILD_DATE)

.PHONY: push push-latest run rm help vars shell prune

## all		: Build all platforms
all: Dockerfile
	docker buildx build -t $(NS)/$(IMAGE_NAME):$(VERSION)-ls$(LS) $(PLATFORMS) $(BUILD) -f Dockerfile .

## build		: build the current platform (default)
build: Dockerfile
	docker buildx build -t $(NS)/$(IMAGE_NAME):$(VERSION)-ls$(LS) $(BUILD) -f Dockerfile .

## build-latest	: Build the latest current platform
build-latest: Dockerfile
	docker buildx build -t $(NS)/$(IMAGE_NAME):latest $(BUILD) -f Dockerfile .

## checksum	: Get the checksum of a file
checksum:
	wget -qO- "https://github.com/kevinpapst/$(IMAGE_NAME)2/releases/download/${VERSION}/$(IMAGE_NAME)-release-${VERSION}.zip" | sha256sum

## date		: Check the image date
date:
	docker exec -it $(CONTAINER_NAME)-$(CONTAINER_INSTANCE) date

## lint		: Lint the Dockerfile with hadolint
lint:	Dockerfile
	hadolint Dockerfile && yamllint .

## load   	: Load the release image
load: Dockerfile
	docker buildx build -t $(NS)/$(IMAGE_NAME):$(VERSION)-ls$(LS) $(BUILD) -f Dockerfile --load .

## load-latest  	: Load the latest image
load-latest: Dockerfile
	docker buildx build -t $(NS)/$(IMAGE_NAME):latest $(BUILD) -f Dockerfile --load .

## monitor	: Monitor the image with snyk
monitor:
	snyk container monitor $(NS)/$(IMAGE_NAME):$(VERSION)-ls$(LS)

## no-cache	: Build with no cache
no-cache:
	docker buildx build -t $(NS)/$(IMAGE_NAME):$(VERSION)-ls$(LS) $(BUILD) -f Dockerfile .

## prune		: Prune the docker builder
prune:
	docker builder prune --all

## push   	: Push the release image
push: Dockerfile
	docker buildx build -t $(NS)/$(IMAGE_NAME):$(VERSION)-ls$(LS) $(BUILD) -f Dockerfile --push .

## push-latest  	: PUsh the latest image
push-latest: Dockerfile
	docker buildx build -t $(NS)/$(IMAGE_NAME):latest $(PLATFORMS) $(BUILD) -f Dockerfile --push .

## push-all 	: Push all release platform images
push-all: Dockerfile
	docker buildx build -t $(NS)/$(IMAGE_NAME):$(VERSION)-ls$(LS) $(PLATFORMS) $(BUILD) -f Dockerfile --push .

## rm   		: Remove the container
rm: stop
	docker rm $(CONTAINER_NAME)-$(CONTAINER_INSTANCE)

## run    	: Run the Docker image
run:
	docker run --rm --name $(CONTAINER_NAME)-$(CONTAINER_INSTANCE) $(PORTS) $(ENV) $(NS)/$(IMAGE_NAME):$(VERSION)-ls$(LS)

## rund   	: Run the Docker image in the background
rund:
	docker run -d --rm --name $(CONTAINER_NAME)-$(CONTAINER_INSTANCE) $(PORTS) $(ENV) $(NS)/$(IMAGE_NAME):$(VERSION)-ls$(LS)

## shell 		: Launch a shell in the container
shell:
	docker exec -it $(CONTAINER_NAME)-$(CONTAINER_INSTANCE) /bin/ash

## stop   	: Stop the Docker container
stop:
	docker stop $(CONTAINER_NAME)-$(CONTAINER_INSTANCE)

## test		: Test the image with snyk
test:
	snyk container test $(NS)/$(IMAGE_NAME):$(VERSION)-ls$(LS) --file=Dockerfile

## help   	: Show help
help: Makefile
	@sed -n 's/^##//p' $<

## vars   	: Show all variables
vars:
	@printf "VERSION 		: %s\n" "$(VERSION)"
	@printf "NS        		: %s\n" "$(NS)"
	@printf "IMAGE_NAME		: %s\n" "$(IMAGE_NAME)"
	@printf "CONTAINER_NAME		:%s\n" " $(CONTAINER_NAME)"
	@printf "CONTAINER_INSTANCE	: %s\n" "$(CONTAINER_INSTANCE)"
	@printf "PORTS 			: %s\n" "$(PORTS)"
	@printf "ENV 			: %s\n" "$(ENV)"
	@echo "PLATFORMS 		: $(PLATFORMS)"
	@echo "CHECKSUM 		: $(CHECKSUM)"
	@echo "BUILD_DATE 		: $(BUILD_DATE)"
	@echo "BUILD 			: $(BUILD)"

default: build
