SERVICES = [
    {
        "service_id": "fuel-delivery",
        "category": "logistics",
        "name": "Fuel Delivery",
        "description": "Fuel transport and delivery coordination for commercial needs.",
        "availability": "available",
        "request_type": "logistics_request",
    },
    {
        "service_id": "cooking-oil-delivery",
        "category": "logistics",
        "name": "Cooking Oil Delivery",
        "description": "Delivery support for cooking oil supply and distribution.",
        "availability": "available",
        "request_type": "logistics_request",
    },
    {
        "service_id": "container-transport",
        "category": "logistics",
        "name": "Container Transport",
        "description": "Container movement for commercial and logistics operations.",
        "availability": "available",
        "request_type": "logistics_request",
    },
    {
        "service_id": "excavator-hire",
        "category": "vehicle_hire",
        "name": "Excavator",
        "description": "Heavy machinery for digging, trenching, and earthmoving.",
        "availability": "available",
        "request_type": "vehicle_hire_request",
    },
    {
        "service_id": "wheel-loader-hire",
        "category": "vehicle_hire",
        "name": "Wheel Loader",
        "description": "Vehicle hire for loading, moving, and site material handling.",
        "availability": "available",
        "request_type": "vehicle_hire_request",
    },
    {
        "service_id": "roller-hire",
        "category": "vehicle_hire",
        "name": "Roller",
        "description": "Compaction equipment for road and paving work.",
        "availability": "unavailable",
        "request_type": "vehicle_hire_request",
    },
    {
        "service_id": "road-paving-blocks",
        "category": "hardware_materials",
        "name": "Road Paving Blocks",
        "description": "Interlocking paving blocks for roads, yards, and construction projects.",
        "availability": "in_stock",
        "request_type": "hardware_material_request",
    },
    {
        "service_id": "construction-tools",
        "category": "hardware_materials",
        "name": "Construction Tools",
        "description": "Tool and hardware requests for construction work.",
        "availability": "available",
        "request_type": "hardware_material_request",
    },
    {
        "service_id": "building-materials",
        "category": "hardware_materials",
        "name": "Building Materials",
        "description": "Material requests coordinated based on customer project needs.",
        "availability": "available_on_request",
        "request_type": "hardware_material_request",
    },
]


def list_services(category=None):
    services = SERVICES

    if category:
        services = [service for service in services if service["category"] == category]

    return sorted(services, key=lambda service: service["service_id"])
