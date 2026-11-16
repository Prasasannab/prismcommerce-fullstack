# GSD Project State

**Active Milestone**: Phase 6 Complete (Core User Journey Delivered)
**Current Phase**: Phase 6: Core User Journey Completion (P0 MVP) (Completed)
**Status**: DONE

## Completed Tasks
- [x] Phase 1: Complete ASP.NET Core 8 Web API with 4 Clean Architecture projects, MediatR CQRS, PostgreSQL via Docker, EF Core migrations, JWT authentication, and Swagger documentation.
- [x] Phase 2: Inventory Concurrency, Pessimistic Row Locking (`SELECT ... FOR UPDATE`), Redis Distributed Caching, and Stripe Payments with Resilient HMAC-SHA256 Webhook Verification.
- [x] Phase 3: Flutter Mobile Frontend Development (Clean Architecture, BLoC, Dio client, Hive offline cart persistence, Shimmer loaders, Hero animations, dynamic variant selector, and custom Slide-to-Pay confirmation widget; 59/59 tests passed).
- [x] Phase 4: Full Multi-Stage Dockerization (`Dockerfile`, `docker-compose.yml` for unified 1-click startup), `UPWORK_PROPOSAL_KIT.md`, `PORTFOLIO_CASE_STUDY.md`, `SPLIT_SCREEN_DEMO_SCRIPT.md`, and complete `README.md`.
- [x] Phase 5: Dynamic Dark & Light Theme System (`AppThemeColors` ThemeExtension, `AppTheme.lightTheme` & `AppTheme.darkTheme`, `ThemeCubit` with Hive persistence in `StorageService`, animated Sun/Moon toggle button in `CatalogHeader`, adaptive UI across all catalog, cart, detail, and checkout widgets; 69/69 tests passed, 0 analyzer issues).
- [x] Milestone 16: Backend Categories Endpoint & Catalog Sorting (`GET /api/v1/categories`, `GetCategoriesQuery` with Redis caching, dynamic sorting `price_asc`, `price_desc`, `newest`, `name` in `GetProductsQuery`; 0 errors, 0 warnings).
- [x] Milestone 17: Mobile Authentication UI & Session Management (`UserModel`, `AuthResponseModel`, `AuthRepository`, `AuthBloc`, `LoginScreen`, `RegisterScreen`, `AuthGuardSheet`, Hive session persistence; 114/114 tests passed, 0 issues).
- [x] Milestone 18: Persistent Bottom Navigation Shell & Account Profile Screen (`MainNavigationShell` with 4 indexed tabs, `ExploreCategoriesScreen` with real-time filtering, `AccountScreen` with theme toggle and profile/settings management, `OrdersScreen` bridge; 131/131 tests passed, 0 analyzer issues).
- [x] Milestone 19: Mobile Order History & Real-Time Tracking Screens (`OrdersRepository` with `/orders/my-orders` and `/orders/{id}`, `OrdersBloc`, `OrderStatusBadge`, `OrderCard`, `OrderTrackingTimeline` 4-stage visual tracker, `OrdersScreen`, `OrderDetailScreen`, and "Track Order" direct routing; 146/146 tests passed).
- [x] Milestone 20: Phase 6 Quality Verification & Automated Tests (Full mobile test suite passing: 146/146 tests, `flutter analyze` 0 issues, .NET backend solution 0 warnings/errors).

## Immediate Next Task
- [ ] Phase 7: Shopping Experience & Admin Tools (Filter & Sort modal, saved shipping address book, wishlist/favorites, admin management endpoints).

## Key Decisions Made
- [2026-11-12]: Selected .NET 8 (targeting `net8.0`) for clean LTS compatibility with C# 12 features.
- [2026-11-12]: Chose MediatR 12 + FluentValidation pipeline behavior for CQRS and automatic validation.
- [2026-11-12]: Structured PostgreSQL integration via Docker Compose with dedicated volumes for local dev consistency.
- [2026-11-12]: Isolated password hashing with BCrypt and token management with HMAC-SHA256 JWT + Refresh Tokens.
