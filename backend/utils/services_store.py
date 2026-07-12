import os

from backend.utils.services_data import list_services as list_seed_services


SERVICES_TABLE_NAME = os.getenv("SERVICES_TABLE_NAME")


def list_services(category=None):
    if not SERVICES_TABLE_NAME:
        return list_seed_services(category)

    import boto3

    table = boto3.resource("dynamodb").Table(SERVICES_TABLE_NAME)
    services = []
    scan_arguments = {}

    while True:
        response = table.scan(**scan_arguments)
        services.extend(response.get("Items", []))

        last_evaluated_key = response.get("LastEvaluatedKey")
        if not last_evaluated_key:
            break

        scan_arguments["ExclusiveStartKey"] = last_evaluated_key

    if category:
        services = [service for service in services if service.get("category") == category]

    return sorted(services, key=lambda service: service.get("service_id", ""))
