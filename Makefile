DB = docker build -t
DP = docker push

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
	$(DB) $(USER_NAME)/blackbox_exporter monitoring/blackbox-exporter

mongo:
	$(DB) $(USER_NAME)/mongodb_exporter:0.20.2 monitoring/mongo-exporter

alertmanager:
	$(DB) $(USER_NAME)/alertmanager monitoring/alertmanager

prometheus:
	$(DB) $(USER_NAME)/prometheus monitoring/prometheus

comment:
	$(DB) $(USER_NAME)/comment src/comment

post:
	$(DB) $(USER_NAME)/post src/post-py

ui:
	$(DB) $(USER_NAME)/ui src/ui

push:
	$(DP) $(USER_NAME)/comment
	$(DP) $(USER_NAME)/post
	$(DP) $(USER_NAME)/ui
	$(DP) $(USER_NAME)/prometheus
	$(DP) $(USER_NAME)/alertmanager
	$(DP) $(USER_NAME)/blackbox_exporter
	$(DP) $(USER_NAME)/mongodb_exporter:0.20.2

.PHONY: blackbox mongo prometheus comment post ui push alertmanager
