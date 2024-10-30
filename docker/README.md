# How to

## Pulling image

```sh
docker pull m0rf30/simonpi
```

## Running container

Please run

```sh
docker run -ti --privileged -v /dev:/dev -v ~/.simonpi:/root/.simonpi m0rf30/simonpi simonpi rpi-X -s Y
```

to generate a Raspberry Pi X image of Y GB

Next fire up your RPIX container with:

```sh
docker run -ti -p 2222:2222 --privileged -v /dev:/dev -v ~/.simonpi:/root/.simonpi m0rf30/simonpi simonpi rpi-X -r
```

## SSHing to the container

Type

```sh
ssh alarm@localhost -p 2222
```

default password for alarm (arch linux arm) user is **alarm**
