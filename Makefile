DBUSER=root
DBPASS=t12yH4di
DBNAME=testing

app=appt:1.0
web=webt:1.0
webservice=webt
apiservice=apit
nginxservice=ngxt
dbservice=dbt
pmaservice=pmat

webcontainer=webt-server
apicontainer=apit-server
nginxcontainer=nginxt-server
dbcontainer=dbt-server

.PHONY: help

help: ## Display this help screen
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf " \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

up: build-app ### Run docker-compose if app image not found will build
	docker-compose up --build -d ${webservice} ${dbservice} ${pmaservice} && docker logs ${webcontainer}
.PHONY: up

down: ### Down docker-compose
	docker-compose down --remove-orphans
.PHONY: down

build-app: ###### Docker Build --platform linux/amd64 -f Dockerfile-test -t ${app} .
# ifeq ($(shell docker images -q ${app} 2> /dev/null),)
	@echo ${app} ${web}
	# docker build -f Dockerfile-local -t ${app} .
	docker build -f Dockerfile-local-web -t ${web} .
.PHONY: build-app

clean: down ### Remove Image Docker
	# docker rmi -f $(shell docker images -q ${app})
	docker rmi -f $(shell docker images -q ${web})
.PHONY: clean

run: up ### Swag run
.PHONY: run

re-dok:	make down ### Restart Compose
	make down && make run

web-bash: ### Run Container App/Nginx
	docker exec -it ${webcontainer} bash
.PHONY: app-bash

api-bash: ### Run Container App/Nginx
	docker exec -it ${apicontainer} bash
.PHONY: api-bash

ngx-bash: ### Run Container App/Nginx
	docker exec -it ${nginxcontainer} bash
.PHONY: ngx-bash

tail-access: ### Check Log Access Nginx
	sudo tail -f ./infra/logs/nginx/access.log
.PHONY: tail-access

tail-error: ### Check Log Error Nginx
	docker logs ${apicontainer} -f
.PHONY: tail-error

tail-php: ### Check Error Log PHP
	sudo tail -f ./infra/logs/php7/error.log
.PHONY: tail-php

###########################################################
# Command Database #
###########################################################
cr-db: ### Create Database on Container
	docker exec -i ${dbcontainer} mysql -u ${DBUSER} --password=${DBPASS} -e "create database ${DBNAME}"
.PHONY: cr-db

cpdb: ### Copy Database .sql to Container
	docker cp infra/dump/${DBNAME}.sql ${dbcontainer}:/tmp
.PHONY: cpdb

migrate: cpdb ### Create New Migration
	docker exec -i ${dbcontainer} mysql -u ${DBUSER} --password=${DBPASS} ${DBNAME} < infra/dump/${DBNAME}.sql
.PHONY: migrate

dump: ### Export Database .sql & Copy to local
	docker exec -i ${dbcontainer} mysqldump -u ${DBUSER} --password=${DBPASS} ${DBNAME} > infra/dump/${DBNAME}.sql
.PHONY: dump

###########################################################
# Command Artisan API #
###########################################################
migration:
	docker exec -it ${apicontainer} php artisan migrate
.PHONY: migration

migration-fresh:
	docker exec -it ${apicontainer} php artisan migrate:fresh
.PHONY: migration

migration-rollback:
	docker exec -it ${apicontainer} php artisan migrate:rollback
.PHONY: migration-rollback

seeder: ### Run Container App/Nginx
	docker exec -it ${apicontainer} php artisan db:seed
.PHONY: seeder

api-nginx-t:
	docker exec ${apicontainer} nginx -t
.PHONY: api-nginx-t

api-nginx-reload:
	docker exec ${apicontainer} service nginx reload
.PHONY: api-nginx-reload