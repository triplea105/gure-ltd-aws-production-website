import logging
import os


SES_SOURCE_EMAIL = os.getenv("SES_SOURCE_EMAIL")
SES_DESTINATION_EMAIL = os.getenv("SES_DESTINATION_EMAIL")

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def build_notification_message(request_item):
    subject = f"New Gure Ltd request: {request_item['service_requested']}"
    body = "\n".join(
        [
            "A new customer request was submitted.",
            "",
            f"Request ID: {request_item['request_id']}",
            f"Type: {request_item['request_type']}",
            f"Service: {request_item['service_requested']}",
            f"Name: {request_item['full_name']}",
            f"Phone: {request_item['phone_number']}",
            f"Email: {request_item.get('email', '')}",
            f"Location: {request_item['location']}",
            "",
            "Message:",
            request_item["message"],
        ]
    )

    return {
        "subject": subject,
        "body": body,
    }


def send_request_notification(request_item):
    if not SES_SOURCE_EMAIL or not SES_DESTINATION_EMAIL:
        return {
            "sent": False,
            "reason": "SES_SOURCE_EMAIL and SES_DESTINATION_EMAIL are not configured",
        }

    import boto3

    message = build_notification_message(request_item)
    client = boto3.client("ses")
    try:
        response = client.send_email(
            Source=SES_SOURCE_EMAIL,
            Destination={
                "ToAddresses": [SES_DESTINATION_EMAIL],
            },
            Message={
                "Subject": {
                    "Data": message["subject"],
                    "Charset": "UTF-8",
                },
                "Body": {
                    "Text": {
                        "Data": message["body"],
                        "Charset": "UTF-8",
                    },
                },
            },
        )
    except Exception as error:
        logger.error(
            "ses_notification_failed request_id=%s error_type=%s",
            request_item["request_id"],
            type(error).__name__,
        )
        return {
            "sent": False,
            "reason": "SES notification failed",
            "error_type": type(error).__name__,
        }

    return {
        "sent": True,
        "message_id": response["MessageId"],
        "source_email": SES_SOURCE_EMAIL,
        "destination_email": SES_DESTINATION_EMAIL,
    }
