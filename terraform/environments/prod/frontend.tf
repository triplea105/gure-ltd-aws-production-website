module "website_bucket" {
  source = "../../modules/s3"

  bucket_name = var.website_bucket_name
  tags        = local.common_tags
}

resource "aws_s3_object" "website_files" {
  for_each = setsubtract(
    fileset(local.website_dir, "**/*"),
    toset(concat(["assets/images/.gitkeep"], var.generate_deployed_api_config ? ["assets/js/config.js"] : []))
  )

  bucket       = module.website_bucket.bucket_name
  key          = each.value
  source       = "${local.website_dir}/${each.value}"
  etag         = filemd5("${local.website_dir}/${each.value}")
  content_type = lookup(local.content_types, lower(element(reverse(split(".", each.value)), 0)), "application/octet-stream")
}

