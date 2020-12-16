# docker-cats

A simple web application which serves different content according to a given environment variable.

Used for testing micro-services architectures.

Image is available at Dockerhub - [unfor19/docker-cats](https://hub.docker.com/r/unfor19/docker-cats)

## Run

Available APP_NAME:

- baby
- green
- dark

```
$ docker run --name cats --rm -p 8080:8080 -d  -e APP_NAME=baby unfor19/docker-cats
```

## Build From Source

```
$ docker build -t unfor19/docker-cats .
```

