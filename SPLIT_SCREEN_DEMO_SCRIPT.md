# 90-Second Split-Screen Video Recording Script (Loom / YouTube Showcase)

This script is engineered to convert high-ticket Upwork and direct clients by visually demonstrating **Full-Stack Ownership**:
- **Left Side of Screen**: Flutter Mobile App Simulator (iOS Simulator or Android Emulator running PrismCommerce).
- **Right Side of Screen**: Terminal showing ASP.NET Core Web API live logs and live PostgreSQL database queries.

---

## Visual Layout Setup
```
┌─────────────────────────────────┬─────────────────────────────────┐
│     LEFT (50% SCREEN WIDTH)     │    RIGHT (50% SCREEN WIDTH)     │
│                                 │                                 │
│    Flutter Mobile Simulator     │    Top: ASP.NET Core API Logs   │
│    (Running iOS / Android)      │    Bottom: Live psql Terminal   │
│                                 │                                 │
└─────────────────────────────────┴─────────────────────────────────┘
```

---

## Second-by-Second Walkthrough

### 00:00 – 00:15 | The Hook (Problem & Full-Stack Ownership)
* **What to Show**: Cursor circling the split screen.
* **Voiceover**:  
  > *"Hey everyone! In this video, I’m demonstrating full-stack architecture for high-concurrency mobile e-commerce. On the left, we have our Flutter 3 mobile app. On the right, our ASP.NET Core 8 Web API running Clean Architecture with CQRS, connected to PostgreSQL and Redis. Watch how actions on the mobile client execute strict transactional database operations in real time."*

---

### 00:15 – 00:35 | Shimmer Loaders & Redis Distributed Caching (Sub-10ms Speed)
* **What to Show**: Pull-to-refresh on the Flutter catalog. Point out the Shimmer skeleton loaders. Then filter categories (`Audio`, `Laptops`, `Wearables`).
* **In the Terminal**: Show the log line `[RedisCacheService] Cache HIT for key: catalog:products:cat_...`.
* **Voiceover**:  
  > *"When browsing our catalog, notice the smooth shimmer skeleton loading states and category filtering. Under the hood, repeated queries don’t hammer the database—they hit our Redis distributed cache with a 10-minute sliding TTL, returning catalog payloads in under 8 milliseconds."*

---

### 00:35 – 00:55 | Dynamic Variant Selection & Real-Time Stock Sync
* **What to Show**: Tap on *Prism Pulse Pods* (notice the smooth Hero image transition). Switch between *Space Black* and *Polar White*.
* **On Screen**: Highlight how the SKU (`PPP-BLK-PRO`), price adjustment, and live stock count (`● In Stock (48 available)`) update instantaneously.
* **Voiceover**:  
  > *"Inside the product detail screen, we have a fluid Hero transition and a dynamic variant selector. Selecting different colors and tiers updates the SKU, price adjustment, and available stock count in real-time, pulling directly from our PostgreSQL inventory records."*

---

### 00:55 – 01:15 | The Superpower: Custom Slide-to-Pay & PostgreSQL Row Locking
* **What to Show**: Tap "Add to Bag", open the Cart sheet, enter coupon code `TECH` (showing 20% discount applied), and drag the **Slide-to-Pay** slider to confirm.
* **In the Terminal**: Show `BEGIN TRANSACTION`, `SELECT ... FOR UPDATE on InventoryRecords`, followed by `COMMIT TRANSACTION`.
* **In PostgreSQL**: Run `SELECT "StockQuantity", "ReservedQuantity" FROM "InventoryRecords";` showing available stock immediately decrementing.
* **Voiceover**:  
  > *"Now for the core superpower: checkout. We open our cart drawer, apply our promo code, and slide to confirm order. Notice the terminal: our MediatR `PlaceOrderCommand` executes a PostgreSQL pessimistic row-level lock—`SELECT ... FOR UPDATE`. This guarantees that even during peak flash sales, two shoppers can never buy the last remaining unit. Stock is reserved instantly."*

---

### 01:15 – 01:30 | Stripe Webhook & Order Confirmation Receipt
* **What to Show**: The Flutter app unlocks the celebratory `OrderConfirmationDialog` with order number and status.
* **In the Terminal**: Show `POST /api/v1/webhooks/stripe` with HMAC-SHA256 signature verification returning `200 OK` and transitioning order status to `Paid`.
* **Voiceover**:  
  > *"Once authorized, Stripe sends a webhook to our API. We cryptographically verify the signature, ensure idempotency, mark the order as paid, and finalize stock fulfillment. If you’re looking for a developer who can own your entire stack from database architecture to mobile client UI, feel free to reach out. Thanks for watching!"*
