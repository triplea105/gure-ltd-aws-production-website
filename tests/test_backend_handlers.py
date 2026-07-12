import json
import os
import unittest
from unittest import mock

from backend.handlers.health import handler as health_handler
from backend.handlers.requests import handler as requests_handler
from backend.handlers.services import handler as services_handler
from backend.utils.dynamodb import put_request_item
from backend.utils.notifications import send_request_notification
from backend.utils.services_store import list_services
from backend.utils.validation import validate_request_payload


class BackendHandlerTests(unittest.TestCase):
    def test_health_handler_returns_ok(self):
        response = health_handler({}, None)
        body = json.loads(response["body"])

        self.assertEqual(response["statusCode"], 200)
        self.assertEqual(body["status"], "ok")

    def test_services_handler_returns_static_services(self):
        response = services_handler({}, None)
        body = json.loads(response["body"])

        self.assertEqual(response["statusCode"], 200)
        self.assertEqual(body["count"], 9)

    def test_services_handler_filters_by_category(self):
        expected_counts = {
            "logistics": 3,
            "vehicle_hire": 3,
            "hardware_materials": 3,
            "unknown": 0,
        }

        for category, expected_count in expected_counts.items():
            with self.subTest(category=category):
                response = services_handler({"pathParameters": {"category": category}}, None)
                body = json.loads(response["body"])

                self.assertEqual(response["statusCode"], 200)
                self.assertEqual(body["count"], expected_count)
                self.assertTrue(all(service["category"] == category for service in body["services"]))

    def test_services_handler_filters_by_query_string(self):
        response = services_handler({"queryStringParameters": {"category": "vehicle_hire"}}, None)
        body = json.loads(response["body"])

        self.assertEqual(response["statusCode"], 200)
        self.assertEqual(body["count"], 3)
        self.assertTrue(all(service["category"] == "vehicle_hire" for service in body["services"]))

    def test_services_store_reads_dynamodb_when_table_name_is_configured(self):
        mock_table = mock.Mock()
        mock_table.scan.side_effect = [
            {
                "Items": [
                    {
                        "service_id": "fuel-delivery",
                        "category": "logistics",
                        "name": "Fuel Delivery",
                    }
                ],
                "LastEvaluatedKey": {"service_id": "fuel-delivery"},
            },
            {
                "Items": [
                    {
                        "service_id": "container-transport",
                        "category": "logistics",
                        "name": "Container Transport",
                    }
                ]
            },
        ]
        mock_resource = mock.Mock()
        mock_resource.Table.return_value = mock_table

        with mock.patch.dict(os.environ, {"SERVICES_TABLE_NAME": "gure-ltd-services"}):
            with mock.patch("backend.utils.services_store.SERVICES_TABLE_NAME", "gure-ltd-services"):
                with mock.patch.dict("sys.modules", {"boto3": mock.Mock(resource=mock.Mock(return_value=mock_resource))}):
                    services = list_services("logistics")

        self.assertEqual(len(services), 2)
        self.assertEqual([service["service_id"] for service in services], ["container-transport", "fuel-delivery"])
        mock_table.scan.assert_has_calls(
            [
                mock.call(),
                mock.call(ExclusiveStartKey={"service_id": "fuel-delivery"}),
            ]
        )

    def test_request_validation_accepts_valid_payload(self):
        errors = validate_request_payload(_valid_payload())

        self.assertEqual(errors, [])

    def test_request_validation_rejects_invalid_phone_and_mismatched_type(self):
        payload = _valid_payload()
        payload["phone_number"] = "not-a-number"
        payload["request_type"] = "vehicle_hire_request"

        errors = validate_request_payload(payload)

        self.assertIn("phone_number must be a valid Kenyan or international number", errors)
        self.assertIn("request_type must match category", errors)

    def test_requests_handler_rejects_invalid_json(self):
        response = requests_handler({"body": "{"}, None)
        body = json.loads(response["body"])

        self.assertEqual(response["statusCode"], 400)
        self.assertEqual(body["error"], "invalid_json")

    def test_requests_handler_accepts_valid_payload_without_aws_dependencies(self):
        response = requests_handler({"body": json.dumps(_valid_payload())}, None)
        body = json.loads(response["body"])

        self.assertEqual(response["statusCode"], 201)
        self.assertEqual(body["status"], "new")
        self.assertFalse(body["storage"]["stored"])
        self.assertFalse(body["notification"]["sent"])
        self.assertIn("request_id", body)

    def test_dynamodb_boundary_writes_when_table_name_is_configured(self):
        mock_table = mock.Mock()
        mock_resource = mock.Mock()
        mock_resource.Table.return_value = mock_table
        request_item = {
            "request_id": "req-test",
            "request_type": "logistics_request",
            "status": "new",
            "created_at": "2026-07-09T10:00:00+00:00",
        }

        with mock.patch.dict(os.environ, {"REQUESTS_TABLE_NAME": "gure-ltd-requests"}):
            with mock.patch("backend.utils.dynamodb.REQUESTS_TABLE_NAME", "gure-ltd-requests"):
                with mock.patch.dict("sys.modules", {"boto3": mock.Mock(resource=mock.Mock(return_value=mock_resource))}):
                    result = put_request_item(request_item)

        self.assertTrue(result["stored"])
        self.assertEqual(result["request_id"], "req-test")
        mock_table.put_item.assert_called_once_with(Item=request_item)

    def test_notification_boundary_sends_when_emails_are_configured(self):
        request_item = _valid_request_item()
        mock_client = mock.Mock()
        mock_client.send_email.return_value = {"MessageId": "message-test"}

        with mock.patch.dict(
            os.environ,
            {
                "SES_SOURCE_EMAIL": "source@example.com",
                "SES_DESTINATION_EMAIL": "destination@example.com",
            },
        ):
            with mock.patch("backend.utils.notifications.SES_SOURCE_EMAIL", "source@example.com"):
                with mock.patch(
                    "backend.utils.notifications.SES_DESTINATION_EMAIL",
                    "destination@example.com",
                ):
                    with mock.patch.dict("sys.modules", {"boto3": mock.Mock(client=mock.Mock(return_value=mock_client))}):
                        result = send_request_notification(request_item)

        self.assertTrue(result["sent"])
        self.assertEqual(result["message_id"], "message-test")
        mock_client.send_email.assert_called_once()

    def test_notification_failure_does_not_undo_stored_request(self):
        call_order = []

        def store_request(request_item):
            call_order.append("stored")
            return {
                "stored": True,
                "request_id": request_item["request_id"],
            }

        def fail_notification(request_item):
            call_order.append("notification_failed")
            return {
                "sent": False,
                "reason": "SES notification failed",
            }

        with mock.patch("backend.handlers.requests.put_request_item", side_effect=store_request):
            with mock.patch(
                "backend.handlers.requests.send_request_notification",
                side_effect=fail_notification,
            ):
                response = requests_handler({"body": json.dumps(_valid_payload())}, None)

        body = json.loads(response["body"])
        self.assertEqual(response["statusCode"], 201)
        self.assertTrue(body["storage"]["stored"])
        self.assertFalse(body["notification"]["sent"])
        self.assertEqual(call_order, ["stored", "notification_failed"])

    def test_notification_boundary_handles_ses_failure(self):
        request_item = _valid_request_item()
        mock_client = mock.Mock()
        mock_client.send_email.side_effect = RuntimeError("SES unavailable")

        with mock.patch("backend.utils.notifications.SES_SOURCE_EMAIL", "source@example.com"):
            with mock.patch("backend.utils.notifications.SES_DESTINATION_EMAIL", "destination@example.com"):
                with mock.patch.dict("sys.modules", {"boto3": mock.Mock(client=mock.Mock(return_value=mock_client))}):
                    result = send_request_notification(request_item)

        self.assertFalse(result["sent"])
        self.assertEqual(result["reason"], "SES notification failed")
        self.assertEqual(result["error_type"], "RuntimeError")


def _valid_payload():
    return {
        "request_type": "logistics_request",
        "category": "logistics",
        "service_requested": "Fuel Delivery",
        "full_name": "Test User",
        "phone_number": "+254700000000",
        "email": "test@example.com",
        "location": "Nairobi",
        "message": "Please send a quote.",
    }


def _valid_request_item():
    return {
        "request_id": "req-test",
        "request_type": "logistics_request",
        "category": "logistics",
        "service_requested": "Fuel Delivery",
        "full_name": "Test User",
        "phone_number": "+254700000000",
        "email": "test@example.com",
        "location": "Nairobi",
        "message": "Please send a quote.",
    }


if __name__ == "__main__":
    unittest.main()
