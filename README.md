# JM-Backend

Job Manager Backend - Microservices Architecture for Company Job Management Platform

## Overview

JM-Backend is a distributed microservices system built for managing company job postings, subscriptions, payments, and talent discovery. The platform supports both Freemium and Premium subscription tiers with different feature access levels.

## Architecture

```
┌────────────────┐
│    Frontend    │
└───────┬────────┘
        │
┌───────▼────────┐
│   JM-Gateway   │ (Port 8072) - API Gateway, Auth, Rate Limiting
└───────┬────────┘
        │
┌───────▼────────┐
│    JM-Eureka   │ (Port 8070) - Service Discovery
└───────┬────────┘
        │
        ├──────────────────┬──────────────────┬──────────────────┐
        │                  │                  │                  │
┌───────▼───────┐  ┌───────▼───────┐  ┌───────▼───────┐  ┌───────▼──────┐
│  Auth (8081)  │  │ Profile(8082) │  │  Subs (8083)  │  │  Pay (8084)  │
└───────┬───────┘  └───────┬───────┘  └───────┬───────┘  └───────┬──────┘
        │                  │                  │                  │
┌───────▼───────┐  ┌───────▼──────┐   ┌───────▼──────┐   ┌───────▼──────┐
│  Jobs (8085)  │  │  Disc (8086) │   │  Noti (8087) │   │  Tags (8088) │
└───────┬───────┘  └──────────────┘   └──────────────┘   └──────────────┘
        │
┌───────▼───────┐
│  Media (8089) │
└───────────────┘
```

## Microservices

### Core Business Services

| Service                           | Port | Description                                     |
| --------------------------------- | ---- | ----------------------------------------------- |
| **JM-CompanyAuthService**         | 8081 | Authentication, JWT tokens, user registration   |
| **JM-CompanyProfileService**      | 8082 | Company profiles, business details (Sharded DB) |
| **JM-CompanySubscriptionService** | 8083 | Subscription management, tier control           |
| **JM-CompanyPaymentService**      | 8084 | Stripe payments, transaction history            |
| **JM-JobPostService**             | 8085 | Job postings, skill tags, search                |
| **JM-ApplicantDiscoveryService**  | 8086 | Talent discovery (Premium only)                 |
| **JM-NotificationService**        | 8087 | Real-time WebSocket notifications               |
| **JM-SkillTagService**            | 8088 | Skill tags repository                           |
| **JM-CompanyMediaService**        | 8089 | File uploads, S3/Azure storage                  |

### Infrastructure Services

| Service        | Port | Description                       |
| -------------- | ---- | --------------------------------- |
| **JM-Eureka**  | 8070 | Service discovery and registry    |
| **JM-Gateway** | 8080 | API Gateway, routing, auth filter |

## Tech Stack

- **Java 17+**
- **Spring Boot 3.x**
- **Spring Cloud** (Gateway, Eureka, Config)
- **PostgreSQL** (with sharding for Profile service)
- **Kafka** - Event-driven communication
- **Redis** - Rate limiting, caching
- **Stripe API** - Payment processing
- **Docker & Docker Compose** - Containerization

## Prerequisites

- Java 17 or higher
- Maven 3.8+
- Docker & Docker Compose
- Stripe account (for payment service)
- GitHub Packages access (for SG-SharedDtoPackage)

## Quick Start

### 1. Configure GitHub Packages (Required)

Set up Maven credentials in `~/.m2/settings.xml` for SG-SharedDtoPackage:

```xml
<servers>
  <server>
    <id>github</id>
    <username>YOUR_GITHUB_USERNAME</username>
    <password>YOUR_GITHUB_TOKEN</password>
  </server>
</servers>
```

See [SG-SharedDtoPackage/README.md](./SG-SharedDtoPackage/README.md) for detailed setup.

### 2. Start All Services

```bash
# Start all services (databases + microservices)
docker compose --profile all up -d --build
```

### 3. Verify Services

- **Eureka Dashboard**: http://localhost:8070
- **API Gateway**: http://localhost:8080
- **Service Health**: http://localhost:8080/actuator/health

## Docker Profiles

### Available Profiles

```bash
# Start only databases
docker compose --profile dbs up -d

# Start profile shards only (shard1, shard2)
docker compose --profile profile-shards up -d

# Start all microservices
docker compose --profile services up -d

# Start everything (recommended)
docker compose --profile all up -d --build
```

### Stop Services

```bash
# Stop all services
docker compose --profile all down

# Stop and remove volumes
docker compose --profile all down -v
```

## Database Sharding

### Profile Service Sharding

The **CompanyProfileService** uses database sharding for horizontal scalability:

- **Shard 1** (Port 5432): Companies with UUID starting `0-7`
- **Shard 2** (Port 5433): Companies with UUID starting `8-F`

Sharding is handled automatically based on the company UUID's first character.

**Example:**

```
Company ID: 11111111-xxxx-xxxx-xxxx-xxxxxxxxxxxx → Shard 1
Company ID: 88888888-xxxx-xxxx-xxxx-xxxxxxxxxxxx → Shard 2
```

## Data Seeding

All services automatically seed test data on first startup:

### Seeded Companies

| Company    | UUID Prefix   | Type     | Email                | Password         | Subscription |
| ---------- | ------------- | -------- | -------------------- | ---------------- | ------------ |
| NAB        | `11111111...` | Freemium | nab@gmail.com        | SecuredPass123!! | EXPIRED      |
| Google     | `22222222...` | Freemium | google@gmail.com     | SecuredPass123!! | CANCELLED    |
| Netcompany | `33333333...` | Premium  | netcompany@gmail.com | SecuredPass123!  | ACTIVE       |
| Shopee     | `44444444...` | Premium  | shopee@gmail.com     | SecuredPass123!  | ACTIVE       |

### Seeded Data Includes

- 4 company accounts (Auth, Profile, Subscription, Payment records)
- 10 job posts (2 per Freemium, 3 per Premium)
- 2 talent discovery profiles (Premium only: Netcompany, Shopee)
- 6 notifications (payment success + expiry alerts)
- 20 skill tags (Java, Python, React, AWS, etc.)

## Subscription Tiers

| Feature              | Freemium | Premium    |
| -------------------- | -------- | ---------- |
| **Job Posts**        | 3 max    | Unlimited  |
| **Talent Discovery** | ❌ No    | ✅ Yes     |
| **Analytics**        | Basic    | Advanced   |
| **Priority Support** | ❌ No    | ✅ Yes     |
| **Monthly Cost**     | Free     | $29.99 USD |

## API Gateway Routes

All client requests go through the Gateway at `http://localhost:8080`:

| Route                   | Service              | Auth Required           |
| ----------------------- | -------------------- | ----------------------- |
| `/api/auth/**`          | Auth Service         | Public (login/register) |
| `/api/profiles/**`      | Profile Service      | ✅ Yes                  |
| `/api/subscriptions/**` | Subscription Service | ✅ Yes                  |
| `/api/payments/**`      | Payment Service      | ✅ Yes                  |
| `/api/jobs/**`          | Job Post Service     | ✅ Yes                  |
| `/api/discovery/**`     | Discovery Service    | ✅ Yes (Premium)        |
| `/api/notifications/**` | Notification Service | ✅ Yes                  |
| `/api/skills/**`        | Skill Tag Service    | ✅ Yes                  |
| `/api/media/**`         | Media Service        | ✅ Yes                  |


## Project Structure

```
JM-Backend/
├── JM-CompanyAuthService/          # Authentication & Authorization
├── JM-CompanyProfileService/       # Company Profiles (Sharded)
├── JM-CompanySubscriptionService/  # Subscription Management
├── JM-CompanyPaymentService/       # Payment Processing (Stripe)
├── JM-JobPostService/              # Job Postings
├── JM-ApplicantDiscoveryService/   # Talent Discovery (Premium)
├── JM-NotificationService/         # Real-time Notifications
├── JM-SkillTagService/             # Skill Tags Repository
├── JM-CompanyMediaService/         # File Upload & Storage
├── JM-Eureka/                      # Service Discovery
├── JM-Gateway/                     # API Gateway
├── SG-SharedDtoPackage/            # Shared DTOs & Avro Schemas
├── docker-compose.yml              # Main orchestration
├── docker-jm-dbs.yml              # Database containers
├── docker-jm-profile-shards.yml   # Profile service shards
└── docker-jm-services.yml         # Microservice containers
```
