import json

from backend.utils.responses import json_response
from backend.utils.dynamodb import build_request_item, put_request_item
from backend.utils.notifications import send_request_notification
from backend.utils.validation import validate_request_payload


def handler(event, context):
    payload, parse_error = _parse_body(event)

    if parse_error:
        return json_response(
            400,
            {
                "error": "invalid_json",
                "message": parse_error,
            },
        )

    validation_errors = validate_request_payload(payload)
    if validation_errors:
        return json_response(
            400,
            {
                "error": "validation_error",
                "message": "Request payload failed validation",
                "details": validation_errors,
            },
        )

    request_item = build_request_item(payload)
    storage_result = put_request_item(request_item)
    notification_result = send_request_notification(request_item)

    return json_response(
        201,
        {
            "message": "Request accepted",
            "request_id": request_item["request_id"],
            "status": request_item["status"],
            "storage": storage_result,
            "notification": notification_result,
        },
    )


def _parse_body(event):
    body = event.get("body") if isinstance(event, dict) else None

    if body is None:
        return {}, "request body is required"

    if isinstance(body, dict):
        return body, None

    try:
        return json.loads(body), None
    except json.JSONDecodeError:
        return {}, "request body must be valid JSON"
