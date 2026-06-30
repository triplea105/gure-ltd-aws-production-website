# Gure Ltd AWS Production Website

## Project Overview

This project builds a secure, scalable, reliable and cost-effective business website for **Gure Ltd**, a construction and logistics company operating in Kenya.

Gure Ltd provides construction materials, construction vehicle hire, hardware/material supplies, and logistics services such as cooking oil delivery, fuel transport, container movement and commercial goods delivery.

The aim of this project is to create a professional company website that also works as a service request platform. Customers should be able to view the company’s services, check what is available, and submit booking or quote requests.

This project is designed to give realistic DevOps and cloud engineering experience, similar to previous ECS, EKS and Lambda projects, while still using the most suitable architecture for this type of business website.

---

## Project Goal

The goal is to build a production-style AWS-hosted website that is:

- Cost-effective
- Scalable
- Secure
- Reliable
- Fault tolerant
- Easy to monitor
- Easy to support after deployment
- Automated using Terraform and GitHub Actions

The project will avoid unnecessary infrastructure such as Kubernetes or ECS in the first version because the main requirement is a public business website with a serverless booking/request backend. Containers can be added later only if the application grows into a larger backend platform.

---

## Business Requirements

The website must allow customers to:

- Learn about Gure Ltd
- View construction and logistics services
- Browse available service categories
- Request logistics services
- Request construction vehicle hire
- Request construction materials or hardware items
- Submit quote or booking requests
- Contact the company directly

The business should be able to:

- Receive customer enquiries
- Store booking and quote requests
- Access submitted customer data
- Check service request history
- Monitor application health
- Receive alerts when failures occur
- Troubleshoot issues using logs and metrics

---

## Website Pages

The website will include the following pages:

| Page | Purpose |
|---|---|
| Home | Presents the company, main services, trust points, projects and quote form |
| About | Explains the company background, mission, values and operating areas |
| Services | Shows all service categories and available options |
| Contact | Allows users to contact the company and request a quote |

The initial navigation will be:

```text
Home
About
Services
Contact
Request a Quote
```

---

## Homepage Requirements

The homepage should have a professional construction and logistics design. It should look similar in structure to a modern construction company website, with a strong hero section, service cards, project images and a clear quote request form.

The homepage should include:

1. **Navigation bar**
   - Gure Ltd logo
   - Home
   - About
   - Services
   - Contact
   - Request a Quote button

2. **Hero section**
   - Large banner image showing construction vehicles, paving blocks and logistics trucks
   - Main heading such as:
     ```text
     Construction Materials, Equipment Hire & Logistics Solutions
     ```
   - Short company description
   - Buttons for:
     - Our Services
     - Request a Quote

3. **Trust strip**
   - Quality assured
   - Reliable delivery
   - Experienced team
   - Kenya-based operations

4. **Services overview**
   - Logistics
   - Construction Vehicle Hire
   - Hardware / Materials
   - Road Paving Blocks

5. **Why choose us**
   - Reliable service
   - Safe operations
   - Professional team
   - Construction and logistics experience

6. **Fleet and logistics preview**
   - Excavators
   - Diggers
   - Wheel loaders
   - Rollers
   - Fuel delivery
   - Cooking oil delivery
   - Container transport

7. **Projects / Gallery preview**
   - Road paving blocks
   - Construction sites
   - Heavy machinery
   - Delivery trucks
   - Containers

8. **Quote request form**
   - Full name
   - Email
   - Phone number
   - Service required
   - Location
   - Message

9. **Footer**
   - Company summary
   - Quick links
   - Services
   - Contact information

---

## Services Requirements

The Services page should group the company’s services into three main categories.

### 1. Logistics

Customers should be able to view and request logistics services.

Example logistics services:

- Fuel delivery
- Cooking oil delivery
- Container transport
- Goods or food delivery
- General commercial transport

Each logistics service should show:

- Service name
- Short description
- Availability status
- Request button
- Booking/quote form

Example availability:

```text
Fuel Delivery - Available
Cooking Oil Delivery - Available
Container Transport - Available
Goods Delivery - Available
```

### 2. Construction Vehicle Hire

Customers should be able to view available construction vehicles and submit hire requests.

Example vehicles:

- Digger
- Excavator
- Wheel loader
- Roller
- Tipper truck

Each vehicle should show:

- Vehicle name
- Description
- Availability
- Hire type
- Request button

Example availability:

```text
Excavator - Available
Wheel Loader - Available
Roller - Unavailable
Tipper Truck - Available
```

### 3. Hardware / Materials

Customers should be able to request construction materials and hardware items.

Example materials:

- Interlocking road paving blocks
- Construction tools
- Building materials
- Other hardware items

Each item should show:

- Item name
- Description
- Stock or availability status
- Request/order button

Example availability:

```text
Road Paving Blocks - In Stock
Construction Tools - Available
Building Materials - Available on Request
```

---

## Booking and Request Flow

The website should allow customers to submit service-specific requests.

### Example Customer Flow

```text
Customer visits website
  -> Opens Services page
  -> Selects Logistics / Vehicle Hire / Hardware
  -> Views available options
  -> Clicks Request / Book
  -> Completes form
  -> Request is sent to API Gateway
  -> Lambda processes request
  -> Request is stored in DynamoDB
  -> Email notification is sent to Gure Ltd
  -> CloudWatch logs the request
```

### Request Types

The backend should support different request types:

```text
logistics_request
vehicle_hire_request
hardware_material_request
general_enquiry
```

---

## Application Architecture

### Public Website

```text
User / Browser
  -> Route 53
  -> CloudFront
  -> Private S3 Bucket
```

### Request Backend

```text
Website Request Form
  -> API Gateway
  -> Lambda
  -> DynamoDB
  -> SES Email Notification
```

### Monitoring and Alerts

```text
CloudWatch Logs / Metrics
  -> CloudWatch Alarms
  -> SNS Topic
  -> Email Alert
```

---

## Why This Architecture Is Suitable

This project uses a static website with a serverless backend because that is the most suitable and cost-effective design for this type of business application.

The website content does not need a continuously running server. It can be hosted using S3 and delivered through CloudFront. The interactive parts, such as bookings and quote requests, can be handled using API Gateway, Lambda and DynamoDB.

This design is cheaper and simpler than ECS or EKS while still being scalable, secure and production-ready.

---

## AWS Services Used

| AWS Service | Purpose |
|---|---|
| Amazon S3 | Stores static website files |
| Amazon CloudFront | Delivers the website securely and improves performance |
| Amazon Route 53 | Manages DNS and custom domain |
| AWS Certificate Manager | Provides HTTPS certificate |
| AWS WAF | Protects the website from unwanted or suspicious traffic |
| API Gateway | Provides public API endpoints for requests |
| AWS Lambda | Runs Python backend logic |
| Amazon DynamoDB | Stores enquiries, bookings and service requests |
| Amazon SES | Sends email notifications to the business |
| Amazon SNS | Sends monitoring alerts |
| Amazon CloudWatch | Logs, metrics, dashboards and alarms |
| IAM | Controls service permissions |
| Terraform | Provisions AWS infrastructure |
| GitHub Actions | Automates validation and deployment |

---

## Application Code

The application will be split into frontend and backend code.

### Frontend

The frontend will be responsible for the website layout and user interaction.

Recommended technologies:

```text
HTML
CSS
JavaScript
```

or later:

```text
React
```

The frontend will include:

- Home page
- About page
- Services page
- Contact page
- Service cards
- Availability display
- Booking/request forms

### Backend

The backend will be written in **Python** and deployed as AWS Lambda functions.

The backend will handle:

- Health checks
- Returning available services
- Processing quote requests
- Processing logistics requests
- Processing vehicle hire requests
- Processing hardware/material requests
- Writing request data to DynamoDB
- Sending email notifications through SES
- Logging activity to CloudWatch

---

## Suggested Repository Structure

```text
.
├── website/
│   ├── index.html
│   ├── about.html
│   ├── services.html
│   ├── contact.html
│   └── assets/
│       ├── css/
│       ├── js/
│       └── images/
├── backend/
│   ├── handlers/
│   │   ├── health.py
│   │   ├── services.py
│   │   ├── requests.py
│   │   └── notifications.py
│   ├── utils/
│   │   ├── dynamodb.py
│   │   ├── responses.py
│   │   └── validation.py
│   └── requirements.txt
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── backend.tf
│   └── modules/
│       ├── s3/
│       ├── cloudfront/
│       ├── route53/
│       ├── acm/
│       ├── waf/
│       ├── api-gateway/
│       ├── lambda/
│       ├── dynamodb/
│       ├── ses/
│       ├── sns/
│       ├── cloudwatch/
│       └── iam/
├── .github/
│   └── workflows/
│       ├── pull-request.yml
│       └── deploy.yml
└── README.md
```

---

## DynamoDB Data Design

The backend will store customer requests in DynamoDB.

### Table: `gure-ltd-requests`

Suggested key design:

```text
Partition key: request_id
```

Example item:

```json
{
  "request_id": "req-001",
  "request_type": "vehicle_hire_request",
  "category": "Construction Vehicle Hire",
  "service_requested": "Excavator",
  "full_name": "Customer Name",
  "phone_number": "+254700000000",
  "email": "customer@example.com",
  "location": "Nairobi, Kenya",
  "message": "I need an excavator for three days.",
  "status": "new",
  "created_at": "2026-06-08T10:00:00Z"
}
```

### Table: `gure-ltd-services`

This table can store service availability.

Suggested key design:

```text
Partition key: service_id
```

Example item:

```json
{
  "service_id": "excavator-hire",
  "category": "Construction Vehicle Hire",
  "name": "Excavator",
  "description": "Heavy machinery for digging, trenching and earthmoving.",
  "availability": "available",
  "request_type": "vehicle_hire_request"
}
```

---

## Data Access

The business or engineer should be able to check application data after deployment.

### AWS Console

```text
DynamoDB
  -> Tables
  -> gure-ltd-requests
  -> Explore table items
```

### AWS CLI

```bash
aws dynamodb scan   --table-name gure-ltd-requests   --region <aws-region>
```

### Data Checks

After submitting a test request, confirm:

- A new request appears in DynamoDB
- Request type is correct
- Customer details are stored
- Service requested is stored
- Status is set to `new`
- Created timestamp is recorded

---

## API Endpoints

Suggested API endpoints:

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/health` | Checks backend health |
| GET | `/services` | Lists all available services |
| GET | `/services/{category}` | Lists services by category |
| POST | `/requests` | Creates a new customer request |

### Health Check Response

```json
{
  "status": "ok",
  "service": "gure-ltd-api"
}
```

### Create Request Example

```bash
curl -X POST https://<api-url>/requests   -H "Content-Type: application/json"   -d '{
    "request_type": "logistics_request",
    "category": "Logistics",
    "service_requested": "Cooking Oil Delivery",
    "full_name": "Customer Name",
    "phone_number": "+254700000000",
    "email": "customer@example.com",
    "location": "Mombasa, Kenya",
    "message": "I need cooking oil delivered to my business."
  }'
```

---

## Monitoring and Application Health

CloudWatch will be used to monitor application health.

### Components to Monitor

| Component | Metrics |
|---|---|
| CloudFront | Requests, 4XX errors, 5XX errors |
| API Gateway | Request count, latency, 4XX errors, 5XX errors |
| Lambda | Invocations, errors, duration, throttles |
| DynamoDB | Successful requests, throttled requests, system errors |
| SES | Email send failures |
| WAF | Blocked requests |

### CloudWatch Dashboard

A dashboard should be created to show:

- CloudFront request count
- CloudFront errors
- API Gateway latency
- API Gateway 4XX/5XX errors
- Lambda invocations
- Lambda errors
- Lambda duration
- Lambda throttles
- DynamoDB throttled requests
- SES email failures
- WAF blocked requests

---

## Alerts

CloudWatch alarms should send alerts through SNS.

### Alert Flow

```text
CloudWatch Alarm
  -> SNS Topic
  -> Email Notification
```

### Recommended Alarms

| Alarm | Reason |
|---|---|
| Lambda errors > 0 | Detects failed backend executions |
| Lambda throttles > 0 | Detects concurrency or scaling issues |
| Lambda duration too high | Detects slow processing |
| API Gateway 5XX errors > 0 | Detects backend failures |
| API Gateway 4XX errors above threshold | Detects repeated bad requests |
| DynamoDB throttled requests > 0 | Detects database capacity issues |
| SES send failures > 0 | Detects email notification problems |
| CloudFront 5XX errors above threshold | Detects website delivery issues |
| WAF blocked request spike | Detects suspicious traffic |

---

## Cost-Effective Design

This architecture is cost-effective because the website does not need always-running servers.

Cost-saving choices:

- Static files hosted in S3
- CloudFront caching
- Lambda runs only when requests are made
- DynamoDB on-demand billing
- No ECS service required initially
- No EKS cluster required initially
- CloudWatch log retention configured
- S3 lifecycle rules for old assets
- Terraform prevents duplicate manual resources

---

## Scalability

The architecture scales automatically through managed AWS services.

Scalability features:

- CloudFront handles high website traffic
- S3 stores and serves static assets
- API Gateway handles API request traffic
- Lambda scales with incoming requests
- DynamoDB scales using on-demand capacity

---

## Security

Security measures:

- S3 bucket kept private
- CloudFront Origin Access Control used
- HTTPS enabled through ACM
- WAF attached to CloudFront
- IAM least privilege policies
- Lambda only allowed to access required DynamoDB tables
- No secrets committed to GitHub
- GitHub Actions secrets used for deployment
- CloudWatch logs used for troubleshooting

---

## Reliability and Fault Tolerance

The project is reliable because it uses AWS managed services rather than a single server.

Fault-tolerant features:

- Static website remains available even if backend requests fail
- CloudFront caches website content
- DynamoDB stores request data reliably
- CloudWatch logs failures
- CloudWatch alarms notify the engineer or business
- SES sends email notifications for requests
- API Gateway and Lambda are managed services

---

## CI/CD Pipeline

GitHub Actions will automate checks and deployment.

### Pull Request Workflow

Runs on pull requests:

```text
Terraform format check
Terraform init
Terraform validate
Terraform plan
Frontend file checks
Backend syntax checks
```

### Deployment Workflow

Runs on merge to main:

```text
1. Checkout repository
2. Configure AWS credentials
3. Run Terraform init
4. Run Terraform validate
5. Run Terraform apply
6. Upload website files to S3
7. Invalidate CloudFront cache
8. Deploy Lambda backend
9. Output website URL and API URL
```

---

## Terraform Commands

```bash
cd terraform
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

---

## Manual Validation Checklist

### Website

- Website loads through the domain
- HTTPS works
- S3 bucket is private
- CloudFront distribution is enabled
- Pages and images load correctly

### Services

- Services page shows Logistics, Vehicle Hire and Hardware categories
- Services show availability
- Booking/request buttons are visible
- Request forms submit correctly

### Backend

- `/health` endpoint returns 200
- `/services` returns service data
- `/requests` accepts valid request data
- Lambda logs appear in CloudWatch

### Data

- Requests are stored in DynamoDB
- Service availability can be checked in DynamoDB
- Test request data is accurate

### Monitoring

- CloudWatch dashboard exists
- Lambda errors are monitored
- API Gateway errors are monitored
- DynamoDB throttles are monitored
- SNS email alerts are configured

### Security

- WAF is attached to CloudFront
- IAM policies are least privilege
- No secrets are stored in the code
- S3 bucket is not publicly accessible

---

## Future Improvements

Future improvements could include:

- Admin dashboard for viewing and updating requests
- Customer login
- Online payment integration
- Booking calendar
- Fleet management
- Logistics tracking
- File upload for delivery documents
- ECS or EKS backend if the platform grows significantly

---

## Project Summary

This project builds a production-style AWS business website for Gure Ltd. The website allows customers to view services, check availability, and submit logistics, vehicle hire and hardware/material requests.

The architecture uses S3, CloudFront, Route 53, ACM, WAF, API Gateway, Lambda, DynamoDB, SES, SNS, CloudWatch, Terraform and GitHub Actions.

It is designed to be cost-effective, scalable, secure, reliable and fault tolerant, while also giving practical cloud and DevOps engineering experience.
