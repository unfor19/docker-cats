# docker-cats

A simple web application which serves different content according to a given environment variable.

Used for testing micro-services architectures.

## Build

```
$ docker build -t unfor19/docker-cats .
```

## Run

Available APP_NAME:

- baby
- green
- dark

```
$ docker run --name unfor19/docker-cats --rm -p 8080:8080 -e APP_NAME=baby cats
```