# GEMINI.md - Context & Instructions for PrismCommerce (Flutter + ASP.NET Core 8)

You are the Lead Full-Stack Architect working on **PrismCommerce**, an enterprise headless e-commerce and high-concurrency inventory platform built with **Flutter (Frontend)** and **ASP.NET Core 8 Web API (Backend) + PostgreSQL**.

## Project Mission
This project is the ultimate competitive showcase for an Upwork Freelancer Portfolio, proving the developer can own the entire tech stack from backend architecture down to mobile client UI, commanding $60–$85/hr contracts ($10,000–$30,000 fixed price).

## Core Rules & Technical Standards
1. **Backend (.NET 8 Clean Architecture + CQRS)**:
   - MediatR commands and queries, Entity Framework Core 8, PostgreSQL.
   - Row-level concurrency locking on PostgreSQL to prevent double-selling inventory during flash sales.
   - Resilient Stripe webhook signature verification (HMAC-SHA256).
   - Redis distributed caching for product catalogs.
2. **Frontend (Flutter Mobile)**:
   - Clean Architecture with BLoC state management and Dio network client.
   - Shimmer skeleton loaders and Hero transitions for product details.
   - Interactive Slide-to-Pay checkout slider widget.
   - Offline cart caching via Hive/Drift.
3. **Dockerization**:
   - Single-command `docker compose up` spinning up PostgreSQL, Redis, and the ASP.NET Core Web API.

Refer to `ROADMAP.md` in this repository for the complete phase-by-phase implementation plan and Upwork showcase deliverables.
