import os
from datetime import datetime, timezone
from uuid import uuid4


REQUESTS_TABLE_NAME = os.getenv("REQUESTS_TABLE_NAME")


def build_request_item(payload):
    timestamp = datetime.now(timezone.utc).isoformat()

    return {
        "request_id": f"req-{uuid4()}",
        "request_type": payload["request_type"],
        "category": payload["category"],
        "service_requested": payload["service_requested"],
        "full_name": payload["full_name"],
        "phone_number": payload["phone_number"],
        "email": payload.get("email", ""),
        "location": payload["location"],
        "message": payload["message"],
        "status": "new",
        "created_at": timestamp,
        "updated_at": timestamp,
    }


def put_request_item(request_item):
    if not REQUESTS_TABLE_NAME:
        return {
            "stored": False,
            "reason": "REQUESTS_TABLE_NAME is not configured",
        }

    import boto3

    table = boto3.resource("dynamodb").Table(REQUESTS_TABLE_NAME)
    table.put_item(Item=request_item)

    return {
        "stored": True,
        "table_name": REQUESTS_TABLE_NAME,
        "request_id": request_item["request_id"],
    }
