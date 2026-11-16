import urllib.request
import urllib.error
import json
import time
import hmac
import hashlib
import sys

BASE_URL = "http://localhost:5000"
WEBHOOK_SECRET = "whsec_prismcommerce_test_webhook_secret_key_12345"

def http_req(url, method="GET", data=None, headers=None):
    if headers is None:
        headers = {}
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as response:
            return response.status, response.read().decode('utf-8')
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode('utf-8')

def generate_stripe_signature(payload_bytes: bytes, secret: str, timestamp: int = None) -> str:
    if timestamp is None:
        timestamp = int(time.time())
    signed_payload = f"{timestamp}.".encode('utf-8') + payload_bytes
    signature = hmac.new(secret.encode('utf-8'), signed_payload, hashlib.sha256).hexdigest()
    return f"t={timestamp},v1={signature}"

def test_stripe_integration():
    print("=================================================================")
    print("PrismCommerce Milestone 8: Stripe & Webhook Verification Suite")
    print("=================================================================\n")

    # Step 1: Login
    print("[1] Authenticating customer (customer@prismcommerce.com)...")
    login_data = json.dumps({
        "email": "customer@prismcommerce.com",
        "password": "Customer123!"
    }).encode('utf-8')
    status, text = http_req(f"{BASE_URL}/api/v1/auth/login", method="POST", data=login_data, headers={"Content-Type": "application/json"})
    assert status == 200, f"Login failed: {status} - {text}"
    token_obj = json.loads(text)
    token = token_obj.get("token") or token_obj.get("accessToken")
    assert token, "Token not found in login response"
    auth_headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    print("    ✓ Login successful! Token acquired.")

    # Step 2: Fetch Products to get variant
    print("\n[2] Fetching active products catalog...")
    status, text = http_req(f"{BASE_URL}/api/v1/products", headers=auth_headers)
    assert status == 200, f"Products failed: {status} - {text}"
    products = json.loads(text)
    assert len(products) > 0, "No products found"

    first_product = products[0]
    first_product_id = first_product["id"]
    status, text = http_req(f"{BASE_URL}/api/v1/products/{first_product_id}", headers=auth_headers)
    assert status == 200, f"Product detail failed: {status} - {text}"
    product_detail = json.loads(text)
    variant = product_detail["variants"][0]
    variant_id = variant["id"]
    sku = variant["sku"]
    initial_stock = variant["availableStock"]
    print(f"    ✓ Target variant: '{variant['title']}' (SKU: {sku}) | Available Stock: {initial_stock}")

    # Step 3: Place Order 1
    print("\n[3] Placing Order 1 (2 units)...")
    order_payload = json.dumps({
        "shippingAddress": "742 Evergreen Terrace, Springfield, OR 97477",
        "items": [
            {
                "productVariantId": variant_id,
                "quantity": 2
            }
        ]
    }).encode('utf-8')
    status, text = http_req(f"{BASE_URL}/api/v1/orders", method="POST", data=order_payload, headers=auth_headers)
    assert status == 201, f"Order creation failed: {status} - {text}"
    order1 = json.loads(text)

    order1_id = order1["id"]
    order1_number = order1["orderNumber"]
    payment_intent_id = order1.get("stripePaymentIntentId")
    client_secret = order1.get("clientSecret")
    order_status = order1.get("status")
    payment_status = order1.get("paymentStatus")

    print(f"    ✓ Order 1 Created: {order1_number} (ID: {order1_id})")
    print(f"    ✓ StripePaymentIntentId: {payment_intent_id}")
    print(f"    ✓ ClientSecret: {client_secret}")
    print(f"    ✓ Order Status: {order_status} | Payment Status: {payment_status}")

    assert payment_intent_id, "StripePaymentIntentId must not be null/empty"
    assert payment_intent_id.startswith("pi_"), f"Unexpected StripePaymentIntentId format: {payment_intent_id}"
    assert client_secret, "ClientSecret must not be null/empty"
    assert client_secret.startswith("pi_"), f"Unexpected ClientSecret format: {client_secret}"
    assert order_status == "Pending", f"Expected Pending, got {order_status}"
    assert payment_status == "Pending", f"Expected Pending, got {payment_status}"

    # Verify inventory was reserved (AvailableStock should decrease by 2)
    status, text = http_req(f"{BASE_URL}/api/v1/products/{first_product['id']}", headers=auth_headers)
    prod_check = json.loads(text)
    var_check = next(v for v in prod_check["variants"] if v["id"] == variant_id)
    print(f"    ✓ Stock check after reservation: Available={var_check['availableStock']} (was {initial_stock})")
    assert var_check["availableStock"] == initial_stock - 2, "Stock reservation failed!"

    # Step 4: Test Webhook with Missing Signature Header -> 400
    print("\n[4] Testing Webhook: Missing Stripe-Signature header...")
    fake_body = json.dumps({"type": "ping"}).encode('utf-8')
    status, text = http_req(f"{BASE_URL}/api/v1/webhooks/stripe", method="POST", data=fake_body, headers={"Content-Type": "application/json"})
    print(f"    ✓ Response Status: {status}")
    assert status == 400, f"Expected 400 Bad Request, got {status}"
    print(f"    ✓ ProblemDetails: {text}")

    # Step 5: Test Webhook with Invalid Signature Header -> 400
    print("\n[5] Testing Webhook: Tampered/Invalid Stripe-Signature header...")
    status, text = http_req(
        f"{BASE_URL}/api/v1/webhooks/stripe",
        method="POST",
        data=fake_body,
        headers={
            "Content-Type": "application/json",
            "Stripe-Signature": "t=1700000000,v1=bad_invalid_signature_hex_digest"
        }
    )
    print(f"    ✓ Response Status: {status}")
    assert status == 400, f"Expected 400 Bad Request, got {status}"
    print(f"    ✓ ProblemDetails: {text}")

    # Step 6: Test Webhook: payment_intent.succeeded with VALID Signature
    print("\n[6] Testing Webhook: payment_intent.succeeded with VALID HMAC-SHA256 signature...")
    current_timestamp = int(time.time())
    amount_cents = int(round(order1["totalAmount"] * 100))
    succeeded_event = {
        "id": f"evt_test_{int(time.time()*1000)}",
        "object": "event",
        "api_version": "2024-06-20",
        "created": current_timestamp,
        "type": "payment_intent.succeeded",
        "data": {
            "object": {
                "id": payment_intent_id,
                "object": "payment_intent",
                "amount": amount_cents,
                "currency": "usd",
                "status": "succeeded",
                "metadata": {
                    "OrderId": order1_id,
                    "OrderNumber": order1_number
                }
            }
        }
    }
    succeeded_bytes = json.dumps(succeeded_event).encode('utf-8')
    valid_signature = generate_stripe_signature(succeeded_bytes, WEBHOOK_SECRET, current_timestamp)

    status, text = http_req(
        f"{BASE_URL}/api/v1/webhooks/stripe",
        method="POST",
        data=succeeded_bytes,
        headers={
            "Content-Type": "application/json",
            "Stripe-Signature": valid_signature
        }
    )
    print(f"    ✓ Response Status: {status} - Body: {text}")
    assert status == 200, f"Expected 200 OK, got {status} - {text}"

    # Verify Order 1 is now Paid
    status, text = http_req(f"{BASE_URL}/api/v1/orders/{order1_id}", headers=auth_headers)
    order1_verify = json.loads(text)
    print(f"    ✓ Order 1 Status after webhook: Status={order1_verify['status']} | PaymentStatus={order1_verify['paymentStatus']}")
    assert order1_verify["status"] == "Paid", f"Expected Paid, got {order1_verify['status']}"
    assert order1_verify["paymentStatus"] == "Succeeded", f"Expected Succeeded, got {order1_verify['paymentStatus']}"

    # Step 7: Test Webhook Idempotency (Re-send payment_intent.succeeded)
    print("\n[7] Testing Webhook: Re-sending payment_intent.succeeded (Idempotency check)...")
    status, text = http_req(
        f"{BASE_URL}/api/v1/webhooks/stripe",
        method="POST",
        data=succeeded_bytes,
        headers={
            "Content-Type": "application/json",
            "Stripe-Signature": valid_signature
        }
    )
    print(f"    ✓ Duplicate Response Status: {status}")
    assert status == 200, f"Expected 200 OK on duplicate event, got {status}"

    # Step 8: Test payment_intent.payment_failed flow
    print("\n[8] Testing payment_intent.payment_failed flow (Place Order 2 -> Payment Failed)...")
    order2_payload = json.dumps({
        "shippingAddress": "123 Failure St, Boston, MA 02101",
        "items": [
            {
                "productVariantId": variant_id,
                "quantity": 1
            }
        ]
    }).encode('utf-8')
    status, text = http_req(f"{BASE_URL}/api/v1/orders", method="POST", data=order2_payload, headers=auth_headers)
    assert status == 201, f"Order 2 failed: {status} - {text}"
    order2 = json.loads(text)
    order2_id = order2["id"]
    order2_number = order2["orderNumber"]
    pi2_id = order2["stripePaymentIntentId"]
    print(f"    ✓ Order 2 Created: {order2_number} (ID: {order2_id}, PI: {pi2_id})")

    failed_event = {
        "id": f"evt_test_fail_{int(time.time()*1000)}",
        "object": "event",
        "api_version": "2024-06-20",
        "created": int(time.time()),
        "type": "payment_intent.payment_failed",
        "data": {
            "object": {
                "id": pi2_id,
                "object": "payment_intent",
                "amount": int(round(order2["totalAmount"] * 100)),
                "currency": "usd",
                "status": "requires_payment_method",
                "last_payment_error": {
                    "message": "The card has expired."
                },
                "metadata": {
                    "OrderId": order2_id,
                    "OrderNumber": order2_number
                }
            }
        }
    }
    failed_bytes = json.dumps(failed_event).encode('utf-8')
    failed_signature = generate_stripe_signature(failed_bytes, WEBHOOK_SECRET)

    status, text = http_req(
        f"{BASE_URL}/api/v1/webhooks/stripe",
        method="POST",
        data=failed_bytes,
        headers={
            "Content-Type": "application/json",
            "Stripe-Signature": failed_signature
        }
    )
    print(f"    ✓ Failed Webhook Response Status: {status} - Body: {text}")
    assert status == 200, f"Expected 200 OK, got {status} - {text}"

    # Verify Order 2 is now Cancelled
    status, text = http_req(f"{BASE_URL}/api/v1/orders/{order2_id}", headers=auth_headers)
    order2_verify = json.loads(text)
    print(f"    ✓ Order 2 Status after failure webhook: Status={order2_verify['status']} | PaymentStatus={order2_verify['paymentStatus']}")
    assert order2_verify["status"] == "Cancelled", f"Expected Cancelled, got {order2_verify['status']}"
    assert order2_verify["paymentStatus"] == "Failed", f"Expected Failed, got {order2_verify['paymentStatus']}"

    # Step 9: Re-send failed webhook (Idempotency)
    print("\n[9] Testing Webhook: Re-sending payment_intent.payment_failed (Idempotency check)...")
    status, text = http_req(
        f"{BASE_URL}/api/v1/webhooks/stripe",
        method="POST",
        data=failed_bytes,
        headers={
            "Content-Type": "application/json",
            "Stripe-Signature": failed_signature
        }
    )
    print(f"    ✓ Duplicate Failed Webhook Response Status: {status}")
    assert status == 200

    print("\n=================================================================")
    print(" ALL MILESTONE 8 STRIPE & WEBHOOK INTEGRATION TESTS PASSED! ")
    print("=================================================================")

if __name__ == "__main__":
    test_stripe_integration()
