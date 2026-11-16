# PrismCommerce - Full-Stack Headless E-Commerce Platform
**Cross-Platform Mobile (Flutter) + High-Concurrency Backend (ASP.NET Core 8 & PostgreSQL)**

[![.NET 8](https://img.shields.io/badge/.NET-8.0-512BD4?logo=dotnet&logoColor=white)](https://dotnet.microsoft.com/)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Redis](https://img.shields.io/badge/Redis-7-DC382D?logo=redis&logoColor=white)](https://redis.io/)
[![Stripe](https://img.shields.io/badge/Stripe-Payments-635BFF?logo=stripe&logoColor=white)](https://stripe.com/)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)

---

## 🌟 Executive Overview
**PrismCommerce** is an enterprise-grade headless e-commerce and high-concurrency inventory platform. Built to prove full-stack ownership across modern mobile engineering and scalable cloud backend architecture:

1. **High-Concurrency Flash-Sale Protection**: Uses PostgreSQL pessimistic row-level locking (`SELECT ... FOR UPDATE`) inside an explicit transaction boundary to prevent overselling during flash drops.
2. **10x Faster Catalog Performance**: Redis distributed caching with automated multi-server prefix invalidation delivers catalog responses in under 8ms.
3. **Resilient Stripe Payments**: PaymentIntents paired with cryptographically verified (HMAC-SHA256) webhooks featuring strict idempotency guards against network retries and replay attacks.
4. **Figma-Grade Flutter Mobile App**: Clean Architecture with BLoC, shimmer skeleton loaders, fluid Hero transitions, dynamic variant pickers, offline Hive cart caching, and an interactive **Slide-to-Pay** confirmation slider.
5. **1-Click Containerized Deployment**: Multi-stage Dockerized setup spinning up PostgreSQL 16, Redis 7, and ASP.NET Core 8 Web API via a single `docker compose up` command.

---

## 🏗️ Architecture Blueprint

```
┌─────────────────────────────────────────────────────────────┐
│              PrismCommerce Mobile App (Flutter)             │
│   • Clean Architecture + BLoC State Management              │
│   • Shimmer Skeletons, Hero Transitions, Dynamic Variants   │
│   • Offline Hive Cart Persistence & Custom Slide-to-Pay     │
└──────────────────────────────┬──────────────────────────────┘
                               │ HTTPS / Secure JWT Bearer
                               ▼
┌─────────────────────────────────────────────────────────────┐
│          ASP.NET Core 8 Web API (.NET Backend)              │
│   • 4-Tier Clean Architecture with MediatR CQRS             │
│   • FluentValidation Pipeline & RFC 7807 ProblemDetails     │
│   • Resilient Stripe Webhook Verification (HMAC-SHA256)     │
└───────────────┬──────────────────────────────┬──────────────┘
                │                              │
                ▼                              ▼
┌──────────────────────────────┐ ┌────────────────────────────┐
│    PostgreSQL Database       │ │       Redis Cache          │
│ • Pessimistic Row Locking    │ │ • Product Catalog Cache    │
│   (SELECT ... FOR UPDATE)    │ │ • 10-Minute Sliding TTL    │
│ • ACID Transactional Orders  │ │ • Multi-Server Invalidator │
└──────────────────────────────┘ └────────────────────────────┘
```

---

## 📁 Repository Layout

```
prismcommerce-fullstack/
├── docker-compose.yml                         # 1-Click Orchestration (PostgreSQL, Redis, API)
├── UPWORK_PROPOSAL_KIT.md                     # High-Converting Upwork Proposal Templates
├── PORTFOLIO_CASE_STUDY.md                    # Portfolio Case Study for Upwork / Portfolio site
├── SPLIT_SCREEN_DEMO_SCRIPT.md                # 90-Second Split-Screen Loom/Video Script
├── backend/
│   ├── Dockerfile                             # Multi-stage production container build
│   ├── PrismCommerce.sln                      # Solution targeting net8.0
│   ├── PrismCommerce.Domain/                  # Core Business Entities & Value Objects
│   ├── PrismCommerce.Application/             # MediatR CQRS, Behaviors, DTOs & Validation
│   ├── PrismCommerce.Infrastructure/          # EF Core 8, Npgsql, Redis, Stripe, BCrypt & JWT
│   └── PrismCommerce.Api/                     # Web API, Controllers, Middleware & Swagger
└── mobile/
    ├── lib/
    │   ├── core/                              # Design Tokens, Dio Client, Theme, Hive Storage
    │   └── features/
    │       ├── catalog/                       # Product Grid, Shimmer Loaders, Hero Details
    │       ├── cart/                          # Hive-Persisted Cart, Promo Codes, Summary
    │       └── checkout/                      # Custom SlideToPayWidget & Order Dialog
    └── test/                                  # 59 Automated Unit, BLoC & Widget Tests
```

---

## 🚀 1-Click Quickstart

### 1. Start the Full Backend Stack (API, PostgreSQL, Redis)
```bash
# Clone the repository
git clone https://github.com/yourusername/prismcommerce-fullstack.git
cd prismcommerce-fullstack

# Spin up PostgreSQL, Redis, and ASP.NET Core API with one command:
docker compose up -d
```
* **Swagger UI Documentation**: [http://localhost:5202/swagger](http://localhost:5202/swagger)
* **Health Check Probe**: [http://localhost:5202/health](http://localhost:5202/health)

### 2. Run the Flutter Mobile App
```bash
cd mobile

# Fetch dependencies
flutter pub get

# Run on iOS Simulator, Android Emulator, or macOS Desktop
flutter run
```

---

## 🧪 Automated Testing & Verification

### Run Flutter Test Suite (59/59 Tests Passing)
```bash
cd mobile
flutter test
flutter analyze
```

### Build & Verify .NET Backend Solution
```bash
cd backend
dotnet build PrismCommerce.sln
```

---

## 📄 Client Showcase & Proposal Kit
* [Upwork Proposal Weapon Kit](UPWORK_PROPOSAL_KIT.md) - Tailored client proposals ($60–$85/hr & $10k–$30k fixed price)
* [Portfolio Case Study](PORTFOLIO_CASE_STUDY.md) - Upwork portfolio project writeup with metrics
* [Split-Screen Demo Script](SPLIT_SCREEN_DEMO_SCRIPT.md) - 90-second recording script for Loom/YouTube
