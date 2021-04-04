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
# ДЗ № 17
## cAdvisor
Добавим запуск cAdvisor для мониторинга контейнеров
```
# docker-compose-monitoring.yml
  cadvisor:
    image: google/cadvisor:v0.29.0
    volumes:
      - "/:/rootfs:ro"
      - "/var/run:/var/run:rw"
      - "/sys:/sys:ro"
      - "/var/lib/docker/:/var/lib/docker:ro"
    ports:
      - "8080:8080"
```
```
# prometheus.yml
  - job_name: "cadvisor"
    static_configs:
      - targets:
          - "cadvisor:8080"
```
## Grafana
Добавим Grafana для визуализации метрик
```
# docker-compose-monitoring.yml
  grafana:
    image: grafana/grafana:5.0.0
    volumes:
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=secret
    depends_on:
      - prometheus
    ports:
      - 3000:3000
volumes:
  grafana_data:
```
## Alertmanager
Добавим Alertmanager для оправки сообшений при проблемах
```
# docker-compose-monitoring.yml
  alertmanager:
    image: ${D_USERNAME}/alertmanager
    environment:
      - SLACK_URL=${SLACK_URL:-https://hooks.slack.com/services/TOKEN}
      - SLACK_CHANNEL=${SLACK_CHANNEL:-general}
      - SLACK_USER=${SLACK_USER:-alertmanager}
    command:
      - '--config.file=/etc/alertmanager/config.yml'
    ports:
      - 9093:9093
```
Alert rules
```
# monitoring/prometheus/alerts.yml
groups:
  - name: alert.rules
    rules:
      - alert: InstanceDown
        expr: up == 0
        for: 1m
        labels:
          severity: page
        annotations:
          description: "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 1 minute"
          summary: "Instance {{ $labels.instance }} down"
```
```
# prometheus.yml
rule_files:
  - "alerts.yml"

alerting:
  alertmanagers:
  - scheme: http
    static_configs:
    - targets:
      - "alertmanager:9093"
```
Docker HUB Repository https://hub.docker.com/u/barmank32
## Задание*
1. Makefile обновлен
2. Docker Engine Metrics.json
3. Docker Metrics Telegraf.json
создание настроенного конфига для Telegraf
```
docker run --rm telegraf:1.17-alpine telegraf -sample-config --input-filter docker_log --output-filter prometheus_client > telegraf.conf
```
4. Отправка на e-mail
5. Сбор метрик с Яндекс.Облака
```
  - job_name: 'yc-monitoring-export'
    metrics_path: '/monitoring/v2/prometheusMetrics'
    params:
      folderId:
        - 'b1g3ohh4eqd4pok4ompb'
      service:
        - 'compute'
    bearer_token_file: 'api-key.yml'
    static_configs:
      - targets: ['monitoring.api.cloud.yandex.net']
        labels:
          folderId: 'b1g3ohh4eqd4pok4ompb'
          service: 'compute'
```
# ДЗ № 18
## ElasticStack
Создадим `docker-compose-logging.yml` с описание закуска `Elasticsearch` `Fluentd` `Kibana`.
### Fluentd
Настойка `Fluentd` находится в файле `logging/fluentd/fluent.conf`
```
<source>
  @type forward
  port 24224
  bind 0.0.0.0
</source>

<match *.**>
  @type copy
  <store>
    @type elasticsearch
    host elasticsearch
    port 9200
    logstash_format true
    logstash_prefix fluentd
    logstash_dateformat %Y%m%d
    include_tag_key true
    type_name access_log
    tag_key @log_name
    flush_interval 1s
  </store>
  <store>
    @type stdout
  </store>
</match>
```
Перенаправляем логи в `Fluentd` к контейнерам приложения добавим
```
    logging:
      driver: "fluentd"
      options:
        fluentd-address: localhost:24224
        tag: service.ui
```
### Kibana
Для лучшей визуализации логов добавим фильтры в `logging/fluentd/fluent.conf`
```
# фильтр для тега service.post
<filter service.post>
  @type parser
  format json
  key_name log
</filter>
# фильтры для тега service.ui
<filter service.ui>
  @type parser
  format grok
  grok_pattern %{RUBY_LOGGER}
  key_name log
</filter>

<filter service.ui>
  @type parser
  format grok
  grok_pattern service=%{WORD:service} \| event=%{WORD:event} \| request_id=%{GREEDYDATA:request_id} \| message='%{GREEDYDATA:message}'
  key_name message
  reserve_data true
</filter>

<filter service.ui>
  @type parser
  format grok
  grok_pattern service=%{WORD:service} \| event=%{WORD:event} \| path=%{URIPATH:pach} \| request_id=%{GREEDYDATA:request_id} \| remote_addr=%{IP:remote_addr} \| method= %{WORD:method} \| response_status=%{INT:response:integer}
  key_name message
  reserve_data true
</filter>
```
## Трайсинг Zipkin
Позволяет отобразить время обработки запроса и выяснить где происходит задержка.
```
# docker-compose-logging.yml
  zipkin:
    image: openzipkin/zipkin:2.21.0
    ports:
      - "9411:9411"
    networks:
      - frontend
      - backend
```
## Задание*
В Zipkin найдена задержка в 3сек при открытии post. В приложении post-py в функция `def find_post(id):` строка 167 обнаружено `        time.sleep(3)`.
# ДЗ № 19
## Введение в Kubernetes
Описывать нечего
# ДЗ № 20
## Установка Minikube
Необходимые компоненты:
- Kubectl

https://kubernetes.io/docs/tasks/tools/install-kubectl/
```
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl
```
- VirtualBox

https://www.virtualbox.org/wiki/Downloads
- Minikube

https://kubernetes.io/docs/tasks/tools/install-minikube/
```
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
sudo dpkg -i minikube_latest_amd64.deb
```
### Minikkube
- `minikube start --kubernetes-version 1.19.7` - запуск
- `minikube service <ui>` - открыть NodePort сервис в браузере
- `minikube service list` - список сервисов
- `minikube addons list` - список росширений
- `minikube addons enable <name>` - запустить аддон
- `minikube stop` - Остановить
### Конфигурирование kubectl
1. Создать cluster:
```
kubectl config set-cluster ... cluster_name
```
2. Создать данные пользователя (credentials)
```
kubectl config set-credentials ... user_name
```
3. Создать контекст
```
  kubectl config set-context context_name \
  --cluster=cluster_name \
  --user=user_name
```
4. Использовать контекст
```
kubectl config use-context context_name
```
### Команды kubectl
- `kubectl get nodes` - список нод
- `kubectl config current-context` - текущий контекст
- `kubectl config get-contexts` - список всех контекстов
- `kubectl apply -f <ui-deployment.yml>` - применить конфигурацию
- `kubectl get deployment` - просмотр диплоймента
- `kubectl get pods --selector component=<ui>` - поиск подов по селектору
- `kubectl port-forward <pod-name> 8080:9292` - проброс порта из пода
- `kubectl describe service <comment>` - просмотреть состояние сервиса
- `kubectl exec -ti <pod-name> nslookup comment` - запустить внутри пода
- `kubectl logs <pod-name>` - логи пода
- `kubectl delete -f <mongodb-service.yml>` - удаление конфигурации
- `kubectl delete service <mongodb>` - удаление сервиса
- `kubectl get nodes -o wide` - Расширенный вывод инфо нод
- `` -
- `` -
## Yandex CloudManaged Service for kubernetes
получить данные для подключения
`yc managed-kubernetes cluster get-credentials <cluster-name ID> --external`
http://178.154.211.253:30812/
![](https://s582sas.storage.yandex.net/rdisk/d7c0e074b75af3ded29c22a9e26cf0b2e111e28756174626d23269d610b7ad0a/605f5ca6/3BI9McPsZKpPOowg2_KMf6BAlbGoSFzXd1Ni9Y1OPSZjv0Q7ara8l9e8in6huSdW1o_bpRSp1-SrOPbDivvHuQ==?uid=0&filename=Screenshot_20210327_152311.jpg&disposition=inline&hash=&limit=0&content_type=image%2Fjpeg&owner_uid=0&fsize=69481&hid=164f04d6b181a44e8e94a4449a9d27d1&media_type=image&tknv=v2&etag=0de17f464e1a89ad321eea539fa46bd8&rtoken=WTkmyvXvic7i&force_default=no&ycrid=na-b0260665bbef3d72314118a6830710f8-downloader9h&ts=5be871b73f580&s=a79f61719a9c3be7eb6c7bb9e56b44667522086a7d4f3d33d3e3b228a9e5a711&pb=U2FsdGVkX1_XggCU3qcOYkX7BIU_V5_G15mMC5dF5l56F_BG90l6WJEJ1MzFi-vW7YN_VqM7S9xDw6hU3n7O9tzKiP2J7KM739nEXUJvaNk)

# ДЗ № 22
Описывать нечего
# ДЗ № 23
## Helm - установка
https://github.com/helm/helm/releases
