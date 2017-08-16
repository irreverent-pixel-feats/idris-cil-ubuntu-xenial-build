IDRIS_VERSION = 1.0
PWD = $(shell pwd)
REPO = irreverentpixelfeats/idris-cil-build
BASE_TAG = ubuntu_xenial_${IDRIS_VERSION}

git-sha:
	bin/git-version ./latest-version
	diff -q latest-version data/version || cp -v latest-version data/version
	rm latest-version

deps: git-sha

build: deps Dockerfile
	docker pull "${REPO}:${BASE_TAG}" || true
	docker build --cache-from "${REPO}:${BASE_TAG}" --tag "${REPO}:${BASE_TAG}" --tag "${REPO}:${BASE_TAG}-$(shell cat data/version)" .

images/idris-cil-build-${BASE_TAG}.tar.gz: build
	docker image save -o "images/idris-cil-build-${BASE_TAG}.tar" "${REPO}:${BASE_TAG}"
	cd images && gzip -v "idris-cil-build-${BASE_TAG}.tar"

image: images/idris-cil-build-${BASE_TAG}.tar.gz

all: build image
