import re


SUPPORTED_REQUEST_TYPES = {
    "logistics_request",
    "vehicle_hire_request",
    "hardware_material_request",
    "general_enquiry",
}

SUPPORTED_CATEGORIES = {
    "logistics",
    "vehicle_hire",
    "hardware_materials",
    "general",
}

REQUEST_TYPE_BY_CATEGORY = {
    "logistics": "logistics_request",
    "vehicle_hire": "vehicle_hire_request",
    "hardware_materials": "hardware_material_request",
    "general": "general_enquiry",
}

REQUIRED_FIELDS = {
    "category",
    "request_type",
    "service_requested",
    "full_name",
    "phone_number",
    "location",
    "message",
}

MAX_MESSAGE_LENGTH = 1000
EMAIL_PATTERN = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
PHONE_PATTERN = re.compile(r"^\+?[0-9\s().-]+$")


def validate_request_payload(payload):
    errors = []

    if not isinstance(payload, dict):
        return ["request body must be a JSON object"]

    for field in sorted(REQUIRED_FIELDS):
        if not _has_value(payload.get(field)):
            errors.append(f"{field} is required")

    request_type = payload.get("request_type")
    if _has_value(request_type) and request_type not in SUPPORTED_REQUEST_TYPES:
        errors.append("request_type must be supported")

    category = payload.get("category")
    if _has_value(category) and category not in SUPPORTED_CATEGORIES:
        errors.append("category must be supported")

    if category in REQUEST_TYPE_BY_CATEGORY and request_type in SUPPORTED_REQUEST_TYPES:
        if REQUEST_TYPE_BY_CATEGORY[category] != request_type:
            errors.append("request_type must match category")

    email = payload.get("email")
    if _has_value(email) and not EMAIL_PATTERN.match(str(email)):
        errors.append("email must be valid")

    phone_number = payload.get("phone_number")
    if _has_value(phone_number):
        phone_text = str(phone_number).strip()
        digit_count = len(re.sub(r"\D", "", phone_text))
        if not PHONE_PATTERN.match(phone_text) or not 7 <= digit_count <= 15:
            errors.append("phone_number must be a valid Kenyan or international number")

    message = payload.get("message")
    if _has_value(message) and len(str(message)) > MAX_MESSAGE_LENGTH:
        errors.append(f"message must be {MAX_MESSAGE_LENGTH} characters or fewer")

    return errors


def _has_value(value):
    return value is not None and str(value).strip() != ""
