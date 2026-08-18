resource "aws_dynamodb_table" "requests" {
  name         = "${local.name_prefix}-requests"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "request_id"

  attribute {
    name = "request_id"
    type = "S"
  }

  attribute {
    name = "request_type"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  global_secondary_index {
    name            = "request_type-created_at-index"
    hash_key        = "request_type"
    range_key       = "created_at"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "status-created_at-index"
    hash_key        = "status"
    range_key       = "created_at"
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = local.common_tags
}

resource "aws_dynamodb_table" "services" {
  name         = "${local.name_prefix}-services"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "service_id"

  attribute {
    name = "service_id"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  tags = local.common_tags
}

resource "aws_dynamodb_table_item" "seed_services" {
  for_each = local.seed_services

  table_name = aws_dynamodb_table.services.name
  hash_key   = aws_dynamodb_table.services.hash_key

  item = jsonencode({
    service_id = {
      S = each.value.service_id
    }
    category = {
      S = each.value.category
    }
    name = {
      S = each.value.name
    }
    description = {
      S = each.value.description
    }
    availability = {
      S = each.value.availability
    }
    request_type = {
      S = each.value.request_type
    }
  })
}

