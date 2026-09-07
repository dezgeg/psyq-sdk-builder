.SUFFIXES:
.SECONDARY:
SHELL := /bin/bash

VERSIONS := 20 26 30 33 35 36 40 41 42 43 44 46 47

.PHONY: all
all: $(addprefix output/,$(VERSIONS))

.PHONY: tarballs
tarballs: $(addsuffix .tar.gz,$(addprefix tarballs/psyq-,$(VERSIONS)))

output/%:
	$(MAKE) -f Makefile.$* $@

tarballs/psyq-%.tar.gz:
	$(MAKE) -f Makefile.$* $@

dl/%:
	$(MAKE) -f Makefile.$* $@

extracted/%:
	$(MAKE) -f Makefile.$* $@

pcsx-redux/bins/Release/psyq-obj-parser:
	cd pcsx-redux && git submodule update --init third_party/fmt third_party/ELFIO third_party/magic_enum third_party/ucl
	$(MAKE) -C pcsx-redux bins/Release/psyq-obj-parser HAS_SUBMODULES=true

.PHONY: clean
clean:
	rm -rf wibo/build
	rm -rf extracted
	rm -rf output

DOCKER_IMAGE ?= psyq-sdk-builder

.PHONY: docker-image
docker-image:
	docker build -t $(DOCKER_IMAGE) .

.PHONY: docker-build
docker-build: docker-image
	docker run --rm --user $(shell id -u):$(shell id -g) -v "$$(pwd)":/src -w /src $(DOCKER_IMAGE) make all

.PHONY: docker-tarballs
docker-tarballs: docker-image
	docker run --rm --user $(shell id -u):$(shell id -g) -v "$$(pwd)":/src -w /src $(DOCKER_IMAGE) make tarballs

.PHONY: docker-shell
docker-shell: docker-image
	docker run --rm -it --user $(shell id -u):$(shell id -g) -v "$$(pwd)":/src -w /src $(DOCKER_IMAGE) bash

.PHONY: docker-run
docker-run: docker-image
	docker run --rm -it --user $(shell id -u):$(shell id -g) -v "$$(pwd)":/src -w /src $(DOCKER_IMAGE) $(CMD)
