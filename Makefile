# Makefile - projet MDD (back Spring Boot + front Angular + MySQL)
# Usage : `make <cible>`. `make help` liste les cibles disponibles.

COMPOSE := docker compose
MVN     := ./mvnw
NPM     := npm

.DEFAULT_GOAL := help

## ----- Docker (stack complète) -----

.PHONY: up
up: .env ## Build + démarre toute la stack (mysql, back, front) en arrière-plan
	$(COMPOSE) up --build -d

.PHONY: down
down: ## Arrête et supprime les conteneurs
	$(COMPOSE) down

.PHONY: stop
stop: ## Arrête les conteneurs sans les supprimer
	$(COMPOSE) stop

.PHONY: restart
restart: down up ## Redémarre la stack

.PHONY: logs
logs: ## Suit les logs de tous les services
	$(COMPOSE) logs -f

.PHONY: ps
ps: ## Liste l'état des conteneurs
	$(COMPOSE) ps

.PHONY: clean
clean: ## Arrête la stack et supprime les volumes (efface la base MySQL !)
	$(COMPOSE) down -v

## ----- Back (Spring Boot / Maven) -----

.PHONY: back-run
back-run: ## Lance le back en local (Maven)
	cd back && $(MVN) spring-boot:run

.PHONY: back-build
back-build: ## Compile et package le back (sans tests)
	cd back && $(MVN) -DskipTests package

.PHONY: back-test
back-test: ## Lance les tests du back
	cd back && $(MVN) test

## ----- Front (Angular) -----

.PHONY: front-install
front-install: ## Installe les dépendances npm du front
	cd front && $(NPM) install

.PHONY: front-serve
front-serve: ## Lance le front en local (ng serve)
	cd front && $(NPM) start

.PHONY: front-build
front-build: ## Build de production du front
	cd front && $(NPM) run build

.PHONY: front-test
front-test: ## Lance les tests du front
	cd front && $(NPM) test

## ----- Utilitaires -----

.env: ## Crée .env depuis .env.exemple s'il n'existe pas
	@test -f .env || (cp .env.exemple .env && echo ">> .env créé depuis .env.exemple — pensez à renseigner les secrets")

.PHONY: secret
secret: .env ## Génère un TOKEN_SECRET aléatoire dans .env s'il est vide
	@if grep -qE '^TOKEN_SECRET=.+' .env; then \
		echo ">> TOKEN_SECRET déjà défini dans .env, rien à faire"; \
	else \
		SECRET=$$(openssl rand -base64 48 | tr -d '\n'); \
		tmp=$$(mktemp); \
		sed "s|^TOKEN_SECRET=.*|TOKEN_SECRET=$$SECRET|" .env > $$tmp && mv $$tmp .env; \
		grep -qE '^TOKEN_SECRET=' .env || echo "TOKEN_SECRET=$$SECRET" >> .env; \
		echo ">> TOKEN_SECRET généré et écrit dans .env"; \
	fi

.PHONY: help
help: ## Affiche cette aide
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'
