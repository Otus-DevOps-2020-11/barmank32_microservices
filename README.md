# barmank32_microservices
barmank32 microservices repository
# ДЗ № 12
[![Build Status](https://travis-ci.com/barmank32/trytravis_microservices.svg?branch=docker-2)](https://travis-ci.com/barmank32/trytravis_microservices)
## Устанавка Docker
```
# Docker
$ sudo apt install docker-ce

# docker-compose
$ sudo apt install docker-compose

# docker-mashin
$ curl -L https://github.com/docker/machine/releases/download/v0.16.2/docker-machine-`uname -s`-`uname -m` >/tmp/docker-machine && \
    chmod +x /tmp/docker-machine && \
    sudo cp /tmp/docker-machine /usr/local/bin/docker-machine
```
### Команды Docker
- `docker version` - версия Docker сервера и клиента
- `docker info` - информация о текущем состоянии
- `docker run hello-world` - запуск контейнера `hello-world`
- `docker ps` - вывод запущенный контейнеров. `-a` показывает все контейнеры.
- `docker images` - список сохраненных образов
- `docker run -it ubuntu:18.04 /bin/bash` - запустить и зайти в контейнер
- `docker start` - запустить остановленный контейнер
- `docker attach` - присоединиться к запущенному контейнеру
- `docker run -dt nginx:latest` - запустить контейнер в фоновом режиме
- `docker exec -it <u_container_id> bash` - запустить новый процесс в контейнере
- `docker commit <u_container_id> yourname/ubuntu-tmp-file` - создать образ из запущенного контейнера
- `docker inspect` - вывод информации о контейнере или образе
- `docker kill` - удалить контейнер
- `docker system df` - отображает сколько дискового пространства занято
- `docker rm` - удалить контейнер. `-f` удалить работающий.
- `docker rmi` -  удалить образ
- `docker rm $(docker ps -a -q)` -  удалит все незапущенные контейнеры
- `docker rmi $(docker images -q)` - удалит все образы
## Docker machine
встроенный в докер инструмент для создания хостов и установки на них docker engine. Имеет поддержку облаков и систем виртуализации.
### Команды
- `docker-machine create <имя>` - создать
- `eval $(docker-machine env<имя>)` - переключиться
- `eval $(docker-machineenv --unset)` - переключиться на локальный
- `docker-machine rm <имя>` - удалить
команда подключения
- `docker-machine ls` - запушенные соединения
```
$ docker-machine create \
  --driver generic \
  --generic-ip-address=<ПУБЛИЧНЫЙ_IP_СОЗДАНОГО_ВЫШЕ_ИНСТАНСА> \
  --generic-ssh-user yc-user \
  --generic-ssh-key ~/.ssh/id_rsa \
    docker-host
```
## Dockerfile
Файл для создания образа контейнера
```
FROM ubuntu:18.04

RUN apt-get update
RUN apt-get install -y mongodb-server ruby-full ruby-dev build-essential git ruby-bundler
RUN apt-get install -y nano net-tools mc

RUN git clone -b monolith https://github.com/express42/reddit.git
COPY mongod.conf /etc/mongod.conf
COPY db_config /reddit/db_config
COPY start.sh /start.sh

RUN chmod 0777 /start.sh
RUN cd /reddit && rm Gemfile.lock && bundle install

CMD ["/start.sh"]
```
`$ docker build -t reddit:latest .` - команда для создания образа
## Docker hub
- `docker login` - аутентификация на docker hub
- `docker tag reddit:latest <your-login>/otus-reddit:1.0` - присвоение тега
- `docker push <your-login>/otus-reddit:1.0` - отправка образа на docker hub
# ДЗ № 13
[![Build Status](https://travis-ci.com/barmank32/trytravis_microservices.svg?branch=docker-3)](https://travis-ci.com/barmank32/trytravis_microservices)
## Новая структура приложения
Создадим три Dockerfile для новой структуры нашего приложения
- для сервиса постов
- для сервиса коментов
- для веб-интерфейса
Соберем наши приложения
```
$ docker build -t barmank32/post:1.0 ./post-py
$ docker build -t barmank32/comment:1.0 ./comment
$ docker build -t barmank32/ui:1.0 ./ui
```
Создадим сеть и запустим контейнеры
```
$ docker network create reddit
$ docker run -d --network=reddit \--network-alias=post_db --network-alias=comment_db mongo:latest
$ docker run -d --network=reddit --network-alias=post barmank32/post:1.0
$ docker run -d --network=reddit --network-alias=comment barmank32/comment:1.0
$ docker run -d --network=reddit -p 9292:9292 barmank32/ui:1.0
```
## Задание*
Остановим и запустим с другими алиасами наши приложения
```
$ docker kill $(docker ps -q)
$ docker run -d --network=reddit --network-alias=mongodb -v reddit_db:/data/db mongo:latest
$ docker run -d --network=reddit --network-alias=app_post --env POST_DATABASE_HOST=mongodb barmank32/post:1.0
$ docker run -d --network=reddit --network-alias=app_comment --env COMMENT_DATABASE_HOST=mongodb barmank32/comment:2.0
$ docker run -d --network=reddit -p 9292:9292 --env POST_SERVICE_HOST=app_post --env COMMENT_SERVICE_HOST=app_comment barmank32/ui:3.0
```
Для сборки образа на Alpine я использовал следующие директивы, остальное осталось без изменения
```
FROM alpine:latest

RUN apk update \
    && apk add --no-cache ruby-full ruby-dev build-base \
    && gem install bundler:1.17.2
```
# ДЗ № 14
[![Build Status](https://travis-ci.com/barmank32/trytravis_microservices.svg?branch=docker-4)](https://travis-ci.com/barmank32/trytravis_microservices)
## Работа с сетью в Docker
Давайте запустим наш проект в 2-х bridge сетях. Так , чтобы сервис ui не имел доступа к базе данных.
```
docker kill $(docker ps -q)
docker run -d --network=back_net --name mongo_db -v reddit_db:/data/db mongo:latest
docker run -d --network=back_net --name post --env POST_DATABASE_HOST=mongo_db barmank32/post:1.0
docker run -d --network=back_net --name comment --env COMMENT_DATABASE_HOST=mongo_db barmank32/comment:2.0
docker run -d --network=front_net -p 9292:9292 barmank32/ui:3.0

docker network connect front_net post
docker network connect front_net comment
```
`docker network connect <network> <container>` подключает контейнер к другой сети.
## Docker-compose
Файл Docker-compose `docker-compose.yml` в нем можно использовать переменные окружения, которые можно записать в файл `.env`
Команды
- `docker-compose up -d` - запустить контейнера в фоне
- `docker-compose ps` - вывод запущенных контейнеров
- `docker-compose down` - выключить и удалить
- `docker-compose config` - проверка и вывод конфигурации
- `docker-compose restart` - перезапуск

Имя контейнера можно задать директивой `container_name: mongo_db`
## Задание*
Запустить контейнер с другими параметрами можно с помощью директивы `command: puma -w 2 --debug`
# ДЗ № 15
## Установка Gitlab CI
Создаем директории под volumes
```
mkdir -p /srv/gitlab/config /srv/gitlab/data /srv/gitlab/logs
```
Подготовим `docker-compose.yml` для запуска Gitlab
```
version: "3.3"
services:
  web:
    image: 'gitlab/gitlab-ce:latest'
    restart: always
    hostname: 'gitlab.example.com'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://84.252.129.209'
    ports:
      - '80:80'
      - '443:443'
      - '2222:22'
    volumes:
      - '/srv/gitlab/config:/etc/gitlab'
      - '/srv/gitlab/logs:/var/log/gitlab'
      - '/srv/gitlab/data:/var/opt/gitlab'

```
Запуск `docker-compose up -d`
## Добавление раннера Gitlab CI
```
docker run -d --name gitlab-runner --restart always -v /srv/gitlab-runner/config:/etc/gitlab-runner -v /var/run/docker.sock:/var/run/docker.sock gitlab/gitlab-runner:latest

docker exec -it gitlab-runner gitlab-runner register \
    --url http://84.252.129.209/ \
    --non-interactive \
    --locked=false \
    --name DockerRunner \
    --executor docker \
    --docker-image alpine:latest \
    --registration-token MLn1YmAeKxhafEtJEBCN \
    --tag-list "linux,xenial,ubuntu,docker" \
    --run-untagged
```
## Настрока Gitlab CI
Пайплаины описываются в файле `.gitlab-ci.yml`
## Задание*
### 2.7*.Автоматизация развёртывания GitLab c16
Реализация автоматического развертывания с помощью terraform и ansible, находится в папке `gitlab-ci`.
### 10.1*. Запуск reddit в контейнере
Реализовано в `.gitlab-ci.yml`. Образ приложения собирается из `Dockerfile` в корне.
### 10.2*. Автоматизация развёртывания GitLabRunner (по желанию)Runner
Реализовано с помощью docker-compose, находится в папке `gitlab-ci` файл docker-compose.run.yml.
### 10.3*.Настройка оповещений в Slack
канал https://devops-team-otus.slack.com/archives/C01G3C63PL7
# ДЗ № 16
## Запуск Prometheus
Запустим Prometheus в Docker
```
$ docker run --rm -p 9090:9090 -d --name prometheus  prom/prometheus
```
## Targets
Target используется для сбора информации
```
  - job_name: "prometheus"
    static_configs:
      - targets:
          - "localhost:9090"
```
## Exporters
Exporter используется для сбора информации не совместимой с Prometheus
Например: Node exporter для сбора информации о работе Docker хоста

### Завершение работы
https://hub.docker.com/r/barmank32/prometheus
https://hub.docker.com/r/barmank32/post
https://hub.docker.com/r/barmank32/comment
https://hub.docker.com/r/barmank32/ui
## Задание*
### мониторинг  MongoDB
Использовал https://github.com/percona/mongodb_exporter/tree/exporter_v2 последней версии 0.20.2
### Blackbox exporter
Использовал https://hub.docker.com/r/prom/blackbox-exporter последней версии
### Makefile
Создан `Makefile` для сборки и отправки образов в регистри.
```
make        - справка
make build  - сборка
make push   - отправка
```



docker run --rm telegraf:1.17-alpine telegraf -sample-config --input-filter docker_log --output-filter prometheus_client > telegraf.conf
