from backend.utils.notifications import build_notification_message, send_request_notification
from backend.utils.responses import json_response


def handler(event, context):
    request_item = event.get("request_item") if isinstance(event, dict) else None

    if not request_item:
        return json_response(
            400,
            {
                "error": "validation_error",
                "message": "request_item is required",
            },
        )

    message = build_notification_message(request_item)
    result = send_request_notification(request_item)

    return json_response(
        200,
        {
            "message": message,
            "notification": result,
        },
    )
