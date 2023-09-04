# .env読み込み
include .env

# Dockerビルド設定
APP_DOCKER_FILE := ./Dockerfile

# Streamlit起動時のTargetファイル
ST_INDEX_FILE := ./app/top.py

# Terraformのディレクトリ
TF_DIR := ./terraform


# Terraformの引数として変数を設定
TF_BACKEND_ARGS := --backend-config "region=$(AWS_REGION)" \
					--backend-config "profile=$(AWS_PROFILE)" \
					--backend-config "bucket=$(TFSTATE_S3_BUCKET)" \
					--backend-config "key=$(TFSTATE_S3_KEY)"

TF_ARGS := -var="aws_region=$(AWS_REGION)" \
			-var="aws_profile=$(AWS_PROFILE)" \
			-var="stage=$(STAGE)" \
			-var="app_name=$(APP_NAME)" \
			-var="lb_subnet_id_list=$(LB_SUBNET_ID_LIST)" \
			-var="app_subnet_id_list=$(APP_SUBNET_ID_LIST)" \
			-var="vpc_id=$(VPC_ID)" \
			-var="local_image_name=$(APP_NAME)" \
			-var="image_name=$(APP_NAME)" \
			-var="container_port=$(CONTAINER_PORT)" \
			-var="container_count=$(CONTAINER_COUNT)"

.PHONY: build-app
build-app: ## Dockerイメージのビルド
	DOCKER_BUILDKIT=1 \
	docker build -t $(APP_NAME):$(STAGE) -f $(APP_DOCKER_FILE) .

.PHONY: tf-init
tf-init: build-app ## Terraform Init
	terraform -chdir=$(TF_DIR) init -reconfigure -upgrade $(TF_BACKEND_ARGS)

.PHONY: tf-apply
tf-apply:tf-init ## Terraform Apply
	terraform -chdir=$(TF_DIR) apply $(TF_ARGS)

.PHONY: tf-destroy
tf-destroy:tf-init ## Terraform Destroy
	terraform -chdir=$(TF_DIR) destroy $(TF_ARGS)

.PHONY: serve-local
serve-local: build-app ## ローカルでの実行テスト
	poetry run streamlit run $(ST_INDEX_FILE)

.PHONY: help
.DEFAULT_GOAL := help
help: ## HELP表示 
	@grep --no-filename -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'