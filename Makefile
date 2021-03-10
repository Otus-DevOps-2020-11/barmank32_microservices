DB = docker build -t
DP = docker push
TAG = logging
ifeq ($(USER_NAME),)
    $(info USER_NAME is empty. Examle export USER_NAME=user)
	exit 1
endif

all:
	@echo "make build - Builds all images"
	@echo "make push - Push all images"

build: monitoring src

monitoring: blackbox mongo prometheus alertmanager
src: comment post ui

blackbox:
	$(DB) $(USER_NAME)/blackbox_exporter:$(TAG) monitoring/blackbox-exporter

mongo:
	$(DB) $(USER_NAME)/mongodb_exporter:$(TAG) monitoring/mongo-exporter

alertmanager:
	$(DB) $(USER_NAME)/alertmanager:$(TAG) monitoring/alertmanager

prometheus:
	$(DB) $(USER_NAME)/prometheus:$(TAG) monitoring/prometheus

telegraf:
	$(DB) $(USER_NAME)/telegraf:$(TAG) monitoring/telegraf

comment:
	$(DB) $(USER_NAME)/comment:$(TAG) src/comment

post:
	$(DB) $(USER_NAME)/post:$(TAG) src/post-py

ui:
	$(DB) $(USER_NAME)/ui:$(TAG) src/ui

push:
	$(DP) $(USER_NAME)/comment:$(TAG)
	$(DP) $(USER_NAME)/post:$(TAG)
	$(DP) $(USER_NAME)/ui:$(TAG)
	$(DP) $(USER_NAME)/prometheus:$(TAG)
	$(DP) $(USER_NAME)/alertmanager:$(TAG)
	$(DP) $(USER_NAME)/telegraf:$(TAG)
	$(DP) $(USER_NAME)/blackbox_exporter:$(TAG)
	$(DP) $(USER_NAME)/mongodb_exporter:$(TAG)

srcpush:
	$(DP) $(USER_NAME)/comment:$(TAG)
	$(DP) $(USER_NAME)/post:$(TAG)
	$(DP) $(USER_NAME)/ui:$(TAG)

.PHONY: blackbox mongo prometheus comment post ui push alertmanager telegraf
