#!make
# One make to rule them all

# For testing purposes, it's possible to load `.env` to the current shell with:
# export $(cat .env.development | xargs)

.ONESHELL:
.EXPORT_ALL_VARIABLES:

# Get OS name
UNAME := $(shell uname)

# Load .env if exists
ifneq ("$(wildcard .env)","")
include .env
endif

# Load .env.${STAGE} if exists
ifneq ("$(wildcard .env.${STAGE})","")
include .env.${STAGE}
endif

# Set BASH_BASH according to host type
ifneq (${CI},true)
# Local on Host
BASH_PATH=/usr/local/bin/bash
ifneq ("$(wildcard /.dockerenv)","")
# Local Docker
BASH_PATH=/bin/bash
endif
else
# CICD
BASH_PATH=/usr/bin/bash
endif

# Set default shell to `bash` instead of `sh`
SHELL=${BASH_PATH}

# Generic Variables
TIMESTAMP:=$(shell date +%s)
DATE_TIMESTAMP:=$(shell date '+%Y-%m-%d')
ROOT_DIR:=${PWD}

# --------------------------------------------------------------
# MODIFY FROM HERE
# --------------------------------------------------------------
# App Static Variables
PROJECT_OWNER=unfor19
PROJECT_NAME=docker-cats
DOCKER_CONTAINER_NAME=cats
DOCKER_CONTAINER_NAME_DEV=${DOCKER_CONTAINER_NAME}-dev
DOCKER_REPOSITORY:=${PROJECT_OWNER}/${PROJECT_NAME}

# App Dynamic Variables
ifndef APP_NAME
APP_NAME=baby
endif

ifndef HOST_PORT
HOST_PORT=8080
endif

ifndef HOST_PORT_DEV
HOST_PORT_DEV=8081
endif

ifndef APP_PORT
APP_PORT=8080
endif

ifndef DOCKER_TAG_APP
DOCKER_TAG_APP=latest
endif

ifndef DOCKER_TAG_DEV
DOCKER_TAG_DEV=latest-dev
endif

# Deployment Variables
AWS_REGION=eu-west-1

# Variables that depend on git
ifndef GIT_BRANCH
GIT_BRANCH=$(shell git rev-parse --abbrev-ref HEAD)
endif
GIT_BRANCH_SLUG=$(subst /,-,$(GIT_BRANCH))

ifndef GIT_BUILD_NUMBER
GIT_BUILD_NUMBER=99999
endif

ifndef GIT_COMMIT
GIT_COMMIT=$(shell git rev-parse HEAD)
endif
GIT_SHORT_COMMIT=$(shell ${GIT_COMMIT:0:8})

# To validate env vars, add "validate-MY_ENV_VAR" 
# as a prerequisite to the relevant target/step
# Based on https://stackoverflow.com/a/7367903/5285732
validate-%:
	@if [[ -z '${${*}}' ]]; then \
	echo 'Environment variable $* not set' && \
	exit 44; \
	fi

##-------
##Generic
##-------
# Removes blank rows - fgrep -v fgrep
# Replace ":" with "" (nothing)
# Print a beautiful table with column
help: ## Available make commands
	@echo
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's~:.* #~~' | column -t -s'#'
	@echo


usage: help


print-path:
	@env | grep ^PATH=


check-requirements: validate-STAGE ## Check requirements for using this project
	@echo Checking requiments ...
	@set -e && \
		bash --version 1>/dev/null && bash --version | grep '5.*' && \
		jq --version 1>/dev/null && jq --version | grep 'jq-1\.6.*' && \
		zip -h 1>/dev/null


##---
##Docker
##---
docker-build-dev: check-requirements ## Build dev Docker image for local development
	docker build --progress=plain -t ${DOCKER_REPOSITORY}:${DOCKER_TAG_DEV} --target dev .


docker-build-app: check-requirements ## Build the client app Docker image
	docker build --progress=plain -t ${DOCKER_REPOSITORY}:${DOCKER_TAG_APP} --target app .


docker-build-all: docker-build-app docker-build-dev ## Builds all Docker images


docker-run-app: check-requirements ## Run app Docker container
	docker run --name ${DOCKER_CONTAINER_NAME} --rm -p ${HOST_PORT}:${APP_PORT} -d -e APP_NAME=${APP_NAME} ${DOCKER_REPOSITORY}:${DOCKER_TAG_APP}


docker-logs-app: check-requirements ## Show logs of app Docker container
	docker logs -f ${DOCKER_CONTAINER_NAME}


docker-exec-app: check-requirements ## Exec into app Docker container for testing purposes
	docker exec -it ${DOCKER_CONTAINER_NAME} bash


docker-stop-app: check-requirements ## Stop app Docker container
	docker stop ${DOCKER_CONTAINER_NAME}


docker-run-dev: check-requirements ## Run dev Docker container for local development
	docker run --rm  -it --name ${DOCKER_CONTAINER_NAME_DEV} -v "${ROOT_DIR}":/code/ -e STAGE -e APP_NAME -p ${HOST_PORT_DEV}:${APP_PORT} ${DOCKER_REPOSITORY}:${DOCKER_TAG_DEV}


docker-stop-dev: check-requirements ## Stop dev Docker container
	docker stop ${DOCKER_CONTAINER_NAME_DEV}


##------
##Lambda
##------
lambda-package: check-requirements ## Package AWS lambda function
	@rm -f ./lambdas/update-cloudflare-dns.zip
	@cd ./lambdas/update-cloudflare-dns/package && zip -rq ../../update-cloudflare-dns.zip . && cd - 1>/dev/null
	@cd ./lambdas/update-cloudflare-dns && zip -g ../update-cloudflare-dns.zip ./main.py && cd - 1>/dev/null
	@ls -lh ./lambdas/update-cloudflare-dns.zip

# AWS_PAGER redirects to stdout instead of "default editor" (vim in my case)
lambda-upload-zip: check-requirements ## Upload ZIP to AWS lambda function
	export AWS_PAGER="" && \
		aws lambda update-function-code --output json \
			--function-name docker-cats-update-cloudflare-dns \
			--zip-file fileb://lambdas/update-cloudflare-dns.zip

lambda-package-upload: lambda-package lambda-upload-zip



