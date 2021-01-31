resource "random_string" "s3_random" {
  length  = 8
  special = false
  upper   = false
}

resource "random_string" "s3_website_random" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "upload_bucket" {
  bucket = "${var.upload_bucket_prefix}-${random_string.s3_random.result}"
  acl    = "private"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST"]
    allowed_origins = ["*"] # TODO change
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_policy" "upload_bucket" {
  bucket = aws_s3_bucket.upload_bucket.id

  policy = <<POLICY
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Effect": "Allow",
         "Principal": "*",
         "Action": [
            "s3:PutObject"
         ],
         "Resource": [            
            "${aws_s3_bucket.upload_bucket.arn}",
            "${aws_s3_bucket.upload_bucket.arn}/*"
         ]
      },
      {
        "Sid": "AllowS3Access",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::796220016242:role/service-role/testS3RoleLambda"
            },
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "${aws_s3_bucket.upload_bucket.arn}",
                "${aws_s3_bucket.upload_bucket.arn}/*"
            ]
      }
   ]
}
POLICY
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.upload_bucket.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.upload_bucket.id

  lambda_function {
    lambda_function_arn = var.lambda_arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

resource "aws_cognito_identity_pool" "default" {
  identity_pool_name               = var.cognito_pool_name
  allow_unauthenticated_identities = true
}

resource "aws_s3_bucket" "website_bucket" {
  bucket = "${var.website_bucket_prefix}-${random_string.s3_website_random.result}"
  acl    = "public-read"
  website {
    index_document = "index.html"
  }
}

resource "aws_s3_bucket_policy" "website_bucket" {
  bucket = aws_s3_bucket.website_bucket.id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "${aws_s3_bucket.website_bucket.arn}/*"
            ]
        }
    ]
}
POLICY
}

resource "aws_s3_bucket_object" "index" {
  bucket       = aws_s3_bucket.website_bucket.bucket
  key          = "index.html"
  source       = "html/index.html"
  etag         = filemd5("html/index.html")
  content_type = "text/html"
}

resource "aws_s3_bucket_object" "js" {
  bucket       = aws_s3_bucket.website_bucket.bucket
  key          = "capture.js"
  source       = "html/capture.js"
  etag         = filemd5("html/capture.js")
  content_type = "text/js"
}

resource "aws_s3_bucket_object" "css" {
  bucket       = aws_s3_bucket.website_bucket.bucket
  key          = "main.css"
  source       = "html/main.css"
  etag         = filemd5("html/main.css")
  content_type = "text/css"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
    domain_name = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id   = "acgMulticloudOrigin"
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "acgMulticloudOrigin"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  enabled             = true
  default_root_object = "index.html"

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_ssm_parameter" "upload_bucket_region" {
  name  = "acg_challenge_upload_bucket_region"
  type  = "String"
  value = aws_s3_bucket.upload_bucket.region
}

data "aws_lambda_function" "existing" {
  function_name = var.lambda_arn
}

data "aws_arn" "role" {
  arn = data.aws_lambda_function.existing.role
}

data "aws_iam_role" "lambda" {
  name = split("/", data.aws_arn.role.resource)[1]
}

resource "aws_iam_policy" "lambda_s3_policy" {
  name = "lambda_s3_policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "${aws_s3_bucket.upload_bucket.arn}/*"
            ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = data.aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}

output "cognito" {
  value = aws_cognito_identity_pool.default.id
}

output "cloudfront" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}
