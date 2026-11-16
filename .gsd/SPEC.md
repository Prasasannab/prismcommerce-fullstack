# PrismCommerce - Phase 1 Technical Specification

## 1. Overview & Objectives
Build a production-grade ASP.NET Core 8 Web API backend using Clean Architecture and CQRS (MediatR), backed by PostgreSQL 16 (running via Docker). This serves as the foundation for high-concurrency inventory operations, Stripe payments, and the Flutter mobile client.

## 2. Technical Stack & Boundaries
- **Runtime & Language**: .NET 8 (C# 12)
- **Architecture**: 4-Tier Clean Architecture (`Domain`, `Application`, `Infrastructure`, `Api`)
- **Patterns**: CQRS with MediatR, Repository/DbContext patterns, Pipeline Behaviors for Validation
- **Database**: PostgreSQL 16 (via Docker container `prismcommerce-postgres`)
- **ORM**: Entity Framework Core 8 (`Npgsql.EntityFrameworkCore.PostgreSQL`)
- **Security & Auth**: JWT (JSON Web Tokens) with Refresh Tokens, BCrypt password hashing, RBAC (Customer, Admin)
- **Validation**: FluentValidation with MediatR IPipelineBehavior
- **API Documentation**: Swagger / OpenAPI with JWT Bearer authorization support
- **Error Handling**: RFC 7807 ProblemDetails Global Exception Middleware

## 3. Project Structure
```
backend/
├── PrismCommerce.sln
├── PrismCommerce.Domain/
│   ├── Common/              # BaseEntity, IAggregateRoot, EntityId
│   ├── Entities/            # User, Product, ProductVariant, InventoryRecord, Category, Order, OrderItem
│   ├── Enums/               # UserRole, OrderStatus, PaymentStatus
│   └── Exceptions/          # DomainException, EntityNotFoundException
├── PrismCommerce.Application/
│   ├── Common/              # Interfaces (IApplicationDbContext, IJwtTokenService, IPasswordHasher), Behaviors
│   ├── Behaviors/           # ValidationBehavior<TRequest, TResponse>
│   ├── DTOs/                # AuthDtos, ProductDtos, CategoryDtos
│   ├── Features/
│   │   ├── Auth/            # Register, Login, RefreshToken (Commands, Handlers, Validators)
│   │   └── Products/        # GetProducts, GetProductById (Queries, Handlers)
│   └── DependencyInjection.cs
├── PrismCommerce.Infrastructure/
│   ├── Data/                # PrismCommerceDbContext, EntityTypeConfigurations, Migrations
│   ├── Services/            # JwtTokenService, PasswordHasher, DateTimeProvider
│   └── DependencyInjection.cs
└── PrismCommerce.Api/
    ├── Controllers/         # AuthController, ProductsController, HealthController
    ├── Middlewares/         # ExceptionHandlingMiddleware
    ├── appsettings.json
    ├── appsettings.Development.json
    └── Program.cs
```

## 4. Domain Model Schema
- **User**: Id (Guid), Email (Unique Index), PasswordHash, FirstName, LastName, Role (UserRole), RefreshToken, RefreshTokenExpiryUtc, CreatedAt, UpdatedAt
- **Category**: Id (Guid), Name, Slug (Unique Index), Description, CreatedAt, UpdatedAt
- **Product**: Id (Guid), CategoryId, Name, Slug (Unique Index), Description, BasePrice, IsActive, ImageUrls (List<string>), CreatedAt, UpdatedAt
- **ProductVariant**: Id (Guid), ProductId, Sku (Unique Index), Title, Color, Size, PriceAdjustment, CreatedAt, UpdatedAt
- **InventoryRecord**: Id (Guid), ProductVariantId (Unique Index), StockQuantity, ReservedQuantity, RowVersion (xmin / uint for concurrency), CreatedAt, UpdatedAt
- **Order**: Id (Guid), OrderNumber (Unique Index), UserId, Status (OrderStatus), TotalAmount, StripePaymentIntentId, CreatedAt, UpdatedAt
- **OrderItem**: Id (Guid), OrderId, ProductVariantId, ProductName, VariantTitle, UnitPrice, Quantity, TotalPrice

## 5. Security & Authentication Requirements
- Password hashed with BCrypt.
- Access token signed using HMAC-SHA256 with minimum 256-bit secret key, 60-minute expiration.
- Cryptographically secure 64-byte random string Refresh Token stored with UTC expiry date (7 days).
- Token refresh endpoint `/api/v1/auth/refresh` validating expiry and issuing new token pair.
- Endpoints secured with `[Authorize]` attributes and Swagger authorization dialog configured for `Bearer <token>`.

## 6. Definition of Done for Phase 1
1. `dotnet build backend/PrismCommerce.sln` succeeds with 0 errors.
2. Docker Compose brings up PostgreSQL (`prismcommerce-postgres`) with persistent storage and healthchecks.
3. EF Core migration applied successfully creating all relational tables and indexes.
4. User registration, login, and token refresh endpoints work via API.
5. Product catalog query endpoint (`/api/v1/products`) returns seeded demo products.
6. Swagger UI runs at `/swagger` with complete interactive schema testing and JWT Bearer authorization support.

---

# PrismCommerce - Phase 2 Technical Specification: Inventory Concurrency & Stripe Payments

## 1. Overview & Objectives
Implement high-concurrency flash-sale inventory reservation, Stripe PaymentIntent creation, resilient Stripe webhook handling with HMAC-SHA256 signature verification and idempotency, and Redis distributed caching for the product catalog.

## 2. Technical Stack & Components
- **Pessimistic Row-Level Locking**: PostgreSQL `SELECT ... FOR UPDATE` via raw SQL / EF Core database transaction to guarantee no two concurrent shoppers can purchase the last in-stock item.
- **Payment Processing**: Stripe SDK (`Stripe.net`), PaymentIntents API.
- **Webhook Resilience**: HMAC-SHA256 cryptographic signature verification using endpoint secret and raw payload bytes.
- **Idempotency**: Strict idempotency guards on webhook events to prevent double-fulfillment on network retries.
- **Distributed Cache**: Redis 7 (via `prismcommerce-redis` Docker container) with `StackExchange.Redis`, caching catalog queries with a 10-minute TTL and invalidation on updates.

## 3. High-Concurrency Flow (Flash Sale Protection)
```
User Placed Order
   │
   ▼
Begin DbTransaction
   │
   ▼
SELECT * FROM "InventoryRecords" WHERE "ProductVariantId" = ANY(@ids) FOR UPDATE
   │
   ├── If AvailableStock < RequestedQuantity ──> Rollback & Throw DomainException("Insufficient stock")
   │
   └── If Stock Sufficient ──> Reserve Stock (StockQuantity -= Qty or ReservedQuantity += Qty)
                                SaveChangesAsync()
                                Commit DbTransaction
   │
   ▼
Create Stripe PaymentIntent (amount, currency: "usd", metadata: { orderId, orderNumber })
   │
   ▼
Return OrderDto with ClientSecret to Mobile / Web Client
```

## 4. Stripe Webhook Architecture
```
Stripe POST /api/v1/webhooks/stripe (Headers: Stripe-Signature)
   │
   ▼
EventUtility.ConstructEvent(rawBody, signature, webhookSecret)
   │
   ├── Invalid Signature ──> Return HTTP 400 Bad Request
   │
   ▼
payment_intent.succeeded
   ├── Lookup Order by StripePaymentIntentId / metadata["orderId"]
   ├── Idempotency Check: if order.PaymentStatus == Succeeded ──> Return HTTP 200 OK
   └── Update Order: Status = Paid, PaymentStatus = Succeeded, SaveChanges
   │
payment_intent.payment_failed
   ├── Lookup Order
   └── Update Order: Status = Cancelled, PaymentStatus = Failed
       Release reserved inventory back to stock
```

## 5. Redis Distributed Caching Architecture
- Cache Keys: `catalog:products:cat:{categoryId}:search:{term}:p:{pageNumber}:s:{pageSize}`
- Query flow:
  1. Check Redis cache. If found, deserialize JSON and return instantly.
  2. If miss, query PostgreSQL via EF Core.
  3. Store result in Redis with 10-minute TTL (`TimeSpan.FromMinutes(10)`).
- Invalidation helper: Pattern matching deletion `catalog:products:*` upon product / stock changes.

## 6. Definition of Done for Phase 2
1. `PlaceOrderCommand` locks inventory rows using `FOR UPDATE`, rejects simultaneous overdrafts, and creates orders.
2. `StripePaymentService` creates PaymentIntents with client secrets.
3. Webhook endpoint `/api/v1/webhooks/stripe` verifies signatures and idempotently transitions order states.
4. Redis cache is active in `GetProductsQueryHandler`, serving cached catalog responses with 10-minute expiration.
5. All automated unit/integration checks pass and `backend/PrismCommerce.sln` builds with 0 errors.

---

# PrismCommerce - Phase 3 Technical Specification: Flutter Mobile Frontend Development

## 1. Overview & Objectives
Build a Figma-grade, production-quality Flutter mobile e-commerce application implementing Clean Architecture, BLoC state management, shimmer skeleton loading, Hero animation transitions, live variant switching, an offline-persisted cart (Hive), and an interactive **Slide-to-Pay** checkout confirmation slider connecting directly to the ASP.NET Core 8 Web API backend.

## 2. Technical Stack & Architecture
- **Framework**: Flutter 3.x (Dart 3.x)
- **Architecture**: Clean Architecture (Presentation, Domain/BLoC, Data/Repositories)
- **State Management**: `flutter_bloc` (BLoC pattern)
- **Network Client**: `dio` (with Bearer JWT interceptor, retry logic, timeout handling)
- **Local Persistence**: `hive` & `hive_flutter` for offline cart caching
- **UI & Animations**: Custom `SlideToPayWidget`, `shimmer` skeletons, Hero image transitions, custom color chips & size badges
- **Visual Design Palette**:
  - Dark Navy Background: `#0B0F19`
  - Card & Surface: `#161E2E` / `#FFFFFF`
  - Electric Cobalt (Primary): `#2563EB`
  - Vibrant Coral (Accent / Discount): `#F43F5E`
  - Emerald Green (Stock Status): `#10B981`

## 3. Screen Flows & Interaction Design
1. **Catalog & Home Screen**:
   - Sticky header with search bar and animated Cart badge counter.
   - Promotional Banner: "Summer Tech Drop 2026 | 20% OFF CODE: TECH".
   - Category selector pills (All, Audio, Laptops, Wearables).
   - Responsive Product Grid with Shimmer skeleton placeholders while loading.
   - Product Card displaying Hero image, title, category, formatted price, rating, and Quick Add button.
2. **Product Detail Screen**:
   - Hero animated image header with back and share buttons.
   - Live Variant Selector: Color and size chips that dynamically update the SKU, price adjustment, and available stock count in real time.
   - Stepper for quantity selection (bounded by available stock).
   - "Add to Bag" sticky bottom bar.
3. **Cart Drawer & Checkout Sheet**:
   - Item list with variant options, quantity adjusters, and swipe-to-delete.
   - Discount coupon code field ("TECH" applies 20% discount).
   - Price breakdown: Subtotal, Discount, Shipping, Total.
   - **Custom `SlideToPayWidget`**:
     - Interactive drag gesture with gradient progress bar.
     - Shimmering chevrons: `>>>>>>> [ SLIDE TO CONFIRM ORDER ($XX.XX) ] >>>>>>>`.
     - Triggers transactional order placement upon completion.
4. **Order Confirmation Receipt**:
   - Animated checkmark, order number, timestamp, line items summary, and "Continue Shopping" action.

## 4. Definition of Done for Phase 3
1. Flutter project compiles with zero analyzer errors (`flutter analyze`).
2. Catalog BLoC and Cart BLoC unit tests pass (`flutter test`).
3. App connects to local ASP.NET Core 8 API, fetches products, and caches cart items in Hive.
4. Slide-to-Pay widget triggers order placement endpoint and handles confirmation seamlessly.

---

# PrismCommerce - Phase 4 Technical Specification: Integration, Dockerization & Upwork Presentation

## 1. Overview & Objectives
Complete the full containerization of the entire tech stack (ASP.NET Core 8 Web API + PostgreSQL 16 + Redis 7) so anyone can run the complete backend with a single `docker compose up` command. Produce the client-conversion Upwork deliverables, portfolio case study, split-screen demo script, and proposal templates to command $60–$85/hr ($10,000–$30,000 contracts).

## 2. Dockerization Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                    docker compose up                        │
└──────────────────────────────┬──────────────────────────────┘
                               │
       ┌───────────────────────┼───────────────────────┐
       ▼                       ▼                       ▼
┌──────────────┐        ┌──────────────┐        ┌──────────────┐
│   Postgres   │        │    Redis     │        │ ASP.NET Core │
│  Container   │        │  Container   │        │ API Container│
│  (Port 5432) │        │  (Port 6379) │        │  (Port 5202) │
└──────▲───────┘        └──────▲───────┘        └──────▲───────┘
       │                       │                       │
       └───────────────────────┴───────────────────────┘
                     Docker Bridge Network
```

- Multi-stage `Dockerfile`:
  - Build stage: `mcr.microsoft.com/dotnet/sdk:8.0`
  - Runtime stage: `mcr.microsoft.com/dotnet/aspnet:8.0`
  - Automated database migration & seed on container launch.
  - Exposes port `8080` mapped to host `5202`.

## 3. Upwork Client-Conversion Kit Deliverables
1. **High-Ticket Proposal Copy**: Pre-tailored cover letter variants targeting startups and mid-market enterprises looking for full-stack Flutter + .NET developers.
2. **Technical Portfolio Case Study**: High-fidelity architectural breakdown emphasizing Full-Stack Ownership, high-concurrency inventory protection, and payment resilience.
3. **Split-Screen Demo Script**: Step-by-step 90-second recording script showcasing Flutter mobile client on the left and ASP.NET Core live logs / PostgreSQL inventory deduction on the right.

## 4. Definition of Done for Phase 4
1. Multi-stage `Dockerfile` created in `backend/` and tested.
2. Root `docker-compose.yml` updated with `api` service dependent on healthy `postgres` and `redis`.
3. `UPWORK_PROPOSAL_KIT.md` and `PORTFOLIO_CASE_STUDY.md` delivered.
4. Project ready for GitHub publishing and portfolio presentation.
