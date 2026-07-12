from backend.utils.responses import json_response
from backend.utils.services_store import list_services


def handler(event, context):
    category = _get_category(event)
    services = list_services(category)

    return json_response(
        200,
        {
            "services": services,
            "count": len(services),
        },
    )


def _get_category(event):
    if not isinstance(event, dict):
        return None

    path_parameters = event.get("pathParameters") or {}
    query_parameters = event.get("queryStringParameters") or {}

    return path_parameters.get("category") or query_parameters.get("category")
