# PrismCommerce - Phase 1 Implementation Roadmap

## Milestone 1: Solution & Project Scaffolding
- [x] Task 1.1: Create `backend/` directory and `PrismCommerce.sln`
- [x] Task 1.2: Scaffold `PrismCommerce.Domain` (Class Library, `net8.0`)
- [x] Task 1.3: Scaffold `PrismCommerce.Application` (Class Library, `net8.0`) with MediatR & FluentValidation packages
- [x] Task 1.4: Scaffold `PrismCommerce.Infrastructure` (Class Library, `net8.0`) with EF Core & Npgsql packages
- [x] Task 1.5: Scaffold `PrismCommerce.Api` (Web API, `net8.0`) with Swashbuckle & JWT Bearer packages
- [x] Task 1.6: Configure project references and verify clean `dotnet build`

## Milestone 2: Domain Layer Entities & Value Objects
- [x] Task 2.1: Implement `BaseEntity` and common domain interfaces/exceptions
- [x] Task 2.2: Implement `User` entity and `UserRole` enum
- [x] Task 2.3: Implement `Category`, `Product`, `ProductVariant`, and `InventoryRecord` entities
- [x] Task 2.4: Implement `Order` and `OrderItem` entities with `OrderStatus` enum

## Milestone 3: Application Layer (CQRS, MediatR, Behaviors & DTOs)
- [x] Task 3.1: Define Application interfaces (`IApplicationDbContext`, `IJwtTokenService`, `IPasswordHasher`)
- [x] Task 3.2: Implement `ValidationBehavior<TRequest, TResponse>` pipeline behavior
- [x] Task 3.3: Implement Auth features: `RegisterCommand`, `LoginCommand`, `RefreshTokenCommand` + FluentValidation rules
- [x] Task 3.4: Implement Product features: `GetProductsQuery`, `GetProductByIdQuery` + DTOs
- [x] Task 3.5: Configure Application `DependencyInjection.cs`

## Milestone 4: Infrastructure Layer (EF Core, PostgreSQL & Security)
- [x] Task 4.1: Create `docker-compose.yml` for PostgreSQL 16 and Redis 7
- [x] Task 4.2: Implement `PrismCommerceDbContext` with Fluent API configurations, indexes, and concurrency tokens
- [x] Task 4.3: Implement `JwtTokenService` and `PasswordHasher` (BCrypt)
- [x] Task 4.4: Configure Infrastructure `DependencyInjection.cs`
- [x] Task 4.5: Generate Initial EF Core Migration and Seed Data (Demo tech catalog items)

## Milestone 5: API Layer, Middleware, Swagger & Verification
- [x] Task 5.1: Implement RFC 7807 `ExceptionHandlingMiddleware` for clean domain & validation error responses
- [x] Task 5.2: Configure `Program.cs` (DI, JWT Authentication, CORS, ProblemDetails, Swagger Bearer Auth)
- [x] Task 5.3: Implement `AuthController` (`/api/v1/auth/register`, `/login`, `/refresh`)
- [x] Task 5.4: Implement `ProductsController` (`/api/v1/products`, `/api/v1/products/{id}`)
- [x] Task 5.5: Run automated verification (Build, Migrations, Docker check, Endpoint verification)

---

# Phase 2: Inventory Concurrency & Stripe Payments

## Milestone 6: Redis Distributed Caching for Catalog Queries
- [x] Task 6.1: Define `ICacheService` interface in `Application/Common/Interfaces/`
- [x] Task 6.2: Implement `RedisCacheService` in `Infrastructure/Services/` using `IConnectionMultiplexer`
- [x] Task 6.3: Configure Redis connection in `Infrastructure/DependencyInjection.cs` and `appsettings.json`
- [x] Task 6.4: Integrate Redis caching with 10-minute TTL into `GetProductsQueryHandler`
- [x] Task 6.5: Verify cache hit and performance against live Redis container

## Milestone 7: Concurrency-Safe Order Placement (Pessimistic Row Locking)
- [x] Task 7.1: Add pessimistic row-level locking method (`SELECT ... FOR UPDATE`) in Infrastructure/Application DB context
- [x] Task 7.2: Create Order DTOs (`OrderDto`, `OrderItemDto`, `PlaceOrderRequest`, `OrderPlacementResultDto`)
- [x] Task 7.3: Implement `PlaceOrderCommand`, `PlaceOrderCommandValidator`, and Handler with transactional inventory locking
- [x] Task 7.4: Implement `OrdersController` (`POST /api/v1/orders`, `GET /api/v1/orders/{id}`, `GET /api/v1/orders/my-orders`)
- [x] Task 7.5: Verify inventory overdraft protection under concurrent attempts

## Milestone 8: Stripe Payments & Resilient Webhook Processing
- [x] Task 8.1: Install `Stripe.net` package in `PrismCommerce.Infrastructure`
- [x] Task 8.2: Define `IPaymentService` in Application & Implement `StripePaymentService` in Infrastructure
- [x] Task 8.3: Configure Stripe keys in `appsettings.json`
- [x] Task 8.4: Wire PaymentIntent creation into Order placement flow
- [x] Task 8.5: Implement `ProcessStripeWebhookCommand` with HMAC-SHA256 signature verification & idempotency guards
- [x] Task 8.6: Implement `WebhooksController` (`POST /api/v1/webhooks/stripe`) reading raw request stream
- [x] Task 8.7: Comprehensive end-to-end verification (Order -> PaymentIntent -> Webhook Success / Failure)

---

# Phase 3: Flutter Mobile Frontend Development

## Milestone 9: Flutter Scaffolding & Core Architecture
- [x] Task 9.1: Scaffold Flutter application in `mobile/` (`flutter create --org com.prismcommerce mobile`)
- [x] Task 9.2: Configure `pubspec.yaml` dependencies (`flutter_bloc`, `dio`, `cached_network_image`, `shimmer`, `hive`, `hive_flutter`, `google_fonts`, `intl`)
- [x] Task 9.3: Setup Clean Architecture core layout (`core/theme`, `core/network`, `core/storage`, `core/constants`)
- [x] Task 9.4: Implement `AppTheme` with dark navy (`#0B0F19`), electric cobalt (`#2563EB`), and vibrant coral (`#F43F5E`)
- [x] Task 9.5: Implement `ApiClient` with Dio, JWT interceptor, error interceptor, and environment-aware base URL
- [x] Task 9.6: Verify clean `flutter analyze` on initial scaffold

## Milestone 10: Product Catalog, Shimmer Loaders & Hero Product Details
- [x] Task 10.1: Implement Catalog Data Layer (Models, DTOs, `CatalogRepository`)
- [x] Task 10.2: Implement `CatalogBloc` with state management (Initial, Loading, Loaded, Error)
- [x] Task 10.3: Build Figma-grade Catalog Screen (Sticky search & cart badge, Summer Tech Drop promo banner, category pills)
- [x] Task 10.4: Build Product Grid with Shimmer skeleton loaders and Hero transitions
- [x] Task 10.5: Build Product Detail Screen with live variant selector (Color chips, Size chips, dynamic SKU, price adjustment, and available stock count)

## Milestone 11: Interactive Cart, Custom Slide-to-Pay & Order Checkout
- [x] Task 11.1: Implement `CartBloc` with Hive local persistence (persists cart items across app restarts)
- [x] Task 11.2: Build Cart Sheet UI (item list, variant summary, quantity adjusters, discount code input for "TECH" - 20% off)
- [x] Task 11.3: Build custom `SlideToPayWidget` with haptic feedback, gradient fill, shimmering chevrons, and drag threshold
- [x] Task 11.4: Connect Slide-to-Pay to `POST /api/v1/orders` and build animated Order Confirmation Receipt dialog
- [x] Task 11.5: Invalidate/refresh catalog stock after order placement

## Milestone 12: Quality Verification & End-to-End Tests
- [x] Task 12.1: Write BLoC unit tests (`test/catalog_bloc_test.dart`, `test/cart_bloc_test.dart`)
- [x] Task 12.2: Run `flutter test` and `flutter analyze`
- [x] Task 12.3: Verify complete client workflow against the active ASP.NET Core API backend

---

# Phase 4: Integration, Dockerization & Upwork Presentation

## Milestone 13: Full Containerization & One-Click Startup
- [x] Task 13.1: Create optimized multi-stage `Dockerfile` in `backend/` for ASP.NET Core 8 API
- [x] Task 13.2: Update root `docker-compose.yml` to orchestrate `api`, `postgres`, and `redis` services
- [x] Task 13.3: Configure environment variables and healthcheck dependencies for reliable 1-click startup (`docker compose up`)
- [x] Task 13.4: Verify API container builds and starts cleanly

## Milestone 14: Upwork Client-Conversion Deliverables & Showcase Kit
- [x] Task 14.1: Create `UPWORK_PROPOSAL_KIT.md` with winning cover letters ($60-$85/hr hourly & $10k-$30k fixed price)
- [x] Task 14.2: Create `PORTFOLIO_CASE_STUDY.md` with architecture diagrams and technical superpower breakdown
- [x] Task 14.3: Create 90-Second Split-Screen Demo Video Script (Flutter on left, ASP.NET Core terminal & PostgreSQL on right)
- [x] Task 14.4: Update root `README.md` with complete project documentation, badges, and quickstart guide

---

# Phase 5: Dynamic Theme System (Dark & Light Mode)

## Milestone 15: Dynamic Dark & Light Theme System
- [x] Task 15.1: Define Light theme design tokens and `AppThemeColors` ThemeExtension in `AppColors` and `AppTheme`
- [x] Task 15.2: Implement `ThemeCubit` and persist active theme in Hive (`StorageService`)
- [x] Task 15.3: Wire `ThemeCubit` into `main.dart` supporting both `AppTheme.darkTheme` and `AppTheme.lightTheme`
- [x] Task 15.4: Add animated Theme toggle button to `CatalogHeader` and `ProductDetailScreen`
- [x] Task 15.5: Adapt catalog, cart, detail, and checkout widgets to dynamically resolve theme colors
- [x] Task 15.6: Verify with automated tests (`flutter test`) and static analysis (`flutter analyze`)

---

# Phase 6: Core User Journey Completion (P0 MVP)

## Milestone 16: Backend Categories Endpoint & Pagination/Sorting Enhancement
- [x] Task 16.1: Implement `GetCategoriesQuery` in `backend/PrismCommerce.Application/Features/Categories/` returning `List<CategoryDto>` with product counts
- [x] Task 16.2: Add `CategoriesController` (`GET /api/v1/categories`) in `backend/PrismCommerce.Api/`
- [x] Task 16.3: Enhance `GetProductsQuery` with `sortBy` parameter (`price_asc`, `price_desc`, `newest`), and `PaginatedList<ProductSummaryDto>` response metadata
- [x] Task 16.4: Verify backend build and test endpoints via curl

## Milestone 17: Mobile Authentication UI & Session Management
- [x] Task 17.1: Implement `AuthRepository` with login, register, token refresh, and profile fetch in `mobile/lib/features/auth/data/`
- [x] Task 17.2: Implement `AuthBloc`, `AuthEvent`, `AuthState` with secure Hive token storage and profile hydration
- [x] Task 17.3: Build Figma-grade `LoginScreen` (Email/password validation, show/hide password, remember me, link to register)
- [x] Task 17.4: Build Figma-grade `RegisterScreen` (First/last name, email, password strength, terms agreement)
- [x] Task 17.5: Connect AuthBloc to `ApiClient` token interceptor and checkout auth guard modal

## Milestone 18: Persistent Bottom Navigation Shell & Account Profile Screen
- [x] Task 18.1: Implement `MainNavigationShell` with smooth animated tab bar (Shop, Explore, My Orders, Account)
- [x] Task 18.2: Implement `AccountScreen` (User avatar & profile info, dark/light theme toggle, order shortcuts, address book link, and logout confirmation)
- [x] Task 18.3: Implement `ExploreCategoriesScreen` with dynamic category grid from `/api/v1/categories` and instant search

## Milestone 19: Mobile Order History & Real-Time Tracking Screens
- [x] Task 19.1: Implement `OrderRepository` connected to `/api/v1/orders/my-orders` and `/api/v1/orders/{id}`
- [x] Task 19.2: Implement `OrdersBloc` managing user order history with pull-to-refresh
- [x] Task 19.3: Build `OrdersListScreen` with order status badges (`Pending`, `Paid`, `Shipped`, `Delivered`, `Cancelled`), item preview thumbnails, and date/pricing summaries
- [x] Task 19.4: Build `OrderDetailScreen` featuring a 4-step interactive order tracking timeline (`Placed` -> `Paid` -> `Processing` -> `Shipped` / `Delivered`), full line items, shipping address, and payment metadata

## Milestone 20: Phase 6 Quality Verification & Automated Tests
- [x] Task 20.1: Unit & Widget tests for `AuthBloc`, `LoginScreen`, `RegisterScreen`, `OrdersBloc`, and `MainNavigationShell`
- [x] Task 20.2: Run `flutter analyze` and `flutter test` verifying 0 errors
- [x] Task 20.3: End-to-end user journey verification (Register -> Login -> Browse Categories -> Add to Cart -> Slide-to-Pay -> View in My Orders & Track)
