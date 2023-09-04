resource "aws_ecr_repository" "this" {
  name                 = var.image_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "image_lifecycle" {
  repository = aws_ecr_repository.this.name


  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Delete more than 5 untagged images",
      "selection": {
        "tagStatus": "untagged",
        "countType": "imageCountMoreThan",
        "countNumber": 5
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}

data "external" "image_hash" {
  program = [
    "/bin/sh", "${path.module}/get_id.sh", "${var.local_image_name}", "${var.local_image_tag}"
  ]
}

resource "null_resource" "push_image" {
  triggers = {
    image_id = data.external.image_hash.result["id"]
  }
  provisioner "local-exec" {
    // ローカルのスクリプトを呼び出す
    command = "sh ${path.module}/push_ecr.sh"

    // スクリプト環境変数
    environment = {
      AWS_PROFILE      = var.aws_profile
      AWS_ACCOUNT_ID   = var.aws_account_id
      AWS_REGION       = var.aws_region
      ECR_URI          = "${aws_ecr_repository.this.repository_url}:${var.image_tag}"
      LOCAL_IMAGE_NAME = var.local_image_name
      LOCAL_IMAGE_TAG  = var.local_image_tag
    }
  }

  depends_on = [aws_ecr_repository.this]
}
