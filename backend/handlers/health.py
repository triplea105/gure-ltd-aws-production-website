import logging

from backend.utils.responses import json_response

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def handler(event, context):
    logger.info("health_check status=ok")

    return json_response(
        200,
        {
            "status": "ok",
            "service": "gure-ltd-api",
        },
    )
