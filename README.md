# Terraform Sample for AWS Fargate and Streamlit

StreamlitをFargateで動かすためのTerraformサンプルです。


## 注意

- `http`を利用した簡易な実装しているので、サービスで利用する場合は `https`にしてください
- 認証は入れていません、[ALBとCognitoを連携させた認証](https://docs.aws.amazon.com/ja_jp/elasticloadbalancing/latest/application/listener-authenticate-users.html)や[Streamlit側でCognitoと連携させる認証](https://github.com/pop-srw/streamlit-cognito-auth)などを含めて検討してください

## 利用方法

`devcontainer`を利用すると環境準備は楽だと思います。

### 1. コードを取得

```sh
git clone https://github.com/yomon8/apprunner-streamlit-sample.git
```


### 2. `.env`ファイルの作成

`.env.sample` を参照して作成してください

```sh
# AWS環境設定
AWS_REGION=ap-northeast-1
AWS_PROFILE=default
VPC_ID=vpc-xxxxx
LB_SUBNET_ID_LIST=subnet-xxxx,subnet-xxxx
APP_SUBNET_ID_LIST=subnet-xxxx,subnet-xxxx

# App設定
STAGE=dev
APP_NAME=streamlit
CONTAINER_PORT=8501
CONTAINER_COUNT=2

# tfstate保存用のS3設定
TFSTATE_S3_BUCKET=your-bucket-name
TFSTATE_S3_KEY=terraform/streamlit.tfstate
```



### 3. デプロイ・動作確認
以下のコマンドでデプロイ可能です。数分でデプロイ完了します。


```sh
make tf-apply
```

デプロイが完了すると、以下のようなメッセージが表示されます。表示されたURLにアクセスすると、Streamlitのサンプルアプリが表示されます。


```sh
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

app_url = "http://xxxxxx-dev-xxxxxx.ap-northeast-1.elb.amazonaws.com"
```


### 4. 環境削除

環境は以下のコマンドで削除可能です。

```sh
make tf-destroy
```
