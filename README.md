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

## References

- [images/baby.jpg](./images/baby.jpg) source https://www.findcatnames.com/great-black-cat-names/ - [img](https://t9b8t3v6.rocketcdn.me/wp-content/uploads/2014/10/black-cat-and-moon.jpg)
- [images/green.jpg](./images/green.jpg) source http://challengethestorm.org/cat-taught-love/ - [img](http://challengethestorm.org/wp-content/uploads/2017/03/cat-2083492_700x426.jpg)
- [images/dark.jpg](./images/dark.jpg) source https://www.maxpixel.net/Animals-Stone-Kitten-Cats-Cat-Flower-Pet-Flowers-2536662
