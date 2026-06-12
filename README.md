# Restaurant App — Upgrade Guide

## What's new

### 🗂 Table identification via QR code
Each table gets its own QR code that encodes a URL:
```
https://yourdomain.com/menu?table=5
```
When a customer scans it, the app reads `?table=5` and stores it. Every order sent to Firebase includes `tableNumber: 5` so the kitchen always knows which table ordered.

### 🎨 UI improvements
- Dark theme with warm amber accent — feels like a real restaurant, not a default Flutter app
- Sticky search bar + category filter chips
- 2-column menu grid with images, tags (Popular / Spicy / Vegan / New), and quantity controls
- Floating cart bar at the bottom (shows count + total, animates on change)
- Item detail bottom sheet on tap
- Real-time order status tracker (Received → Confirmed → Preparing → Ready → Served)

### 🧱 Architecture
- `CartProvider` (ChangeNotifier) — all cart state in one place
- `FirebaseService` — Firestore streams/writes
- `AppTheme` — single source of truth for colors and typography

---

## Setup

### 1. Add Firebase
Replace `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) with your project's files.

### 2. Firestore structure

**`menu` collection:**
```json
{
  "name": "Margherita Pizza",
  "description": "San Marzano tomato, mozzarella, basil",
  "price": 38.5,
  "category": "Pizza",
  "imageUrl": "https://...",
  "available": true,
  "tags": ["popular", "vegan"]
}
```

**`orders` collection (written by the app):**
```json
{
  "tableNumber": 5,
  "items": [
    { "itemId": "abc", "name": "Margherita Pizza", "price": 38.5, "quantity": 2, "subtotal": 77.0 }
  ],
  "total": 77.0,
  "status": "pending",
  "createdAt": "2024-01-15T19:30:00.000Z",
  "timestamp": 1705347000000,
  "customerNote": "No onions please"
}
```

### 3. Configure deep links

**Android** — `android/app/src/main/AndroidManifest.xml`:
```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="https" android:host="yourdomain.com" android:pathPrefix="/menu" />
</intent-filter>
```

**iOS** — `ios/Runner/Info.plist` (for custom scheme fallback):
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array><string>restaurantapp</string></array>
  </dict>
</array>
```
For universal links, add your domain to `ios/Runner/Runner.entitlements`.

### 4. Generate QR codes
Open `QrGeneratorScreen` (accessible from a hidden admin route or run separately). Set the base URL to your domain and print the QR codes for each table.

### 5. Kitchen app integration
The kitchen app should:
1. Listen to `orders` where `status == "pending"`
2. Show `tableNumber` prominently
3. Update `status` field (`confirmed` → `preparing` → `ready` → `served`)

The customer app polls `status` in real time via `orderStatusStream`.

---

## File structure
```
lib/
├── main.dart                   # Entry point + deep link handling
├── theme/
│   └── app_theme.dart          # Colors, fonts, component themes
├── models/
│   ├── menu_item.dart
│   └── order.dart              # Order, CartItem, OrderStatus
├── services/
│   ├── firebase_service.dart   # Firestore reads/writes
│   └── cart_provider.dart      # Cart state (ChangeNotifier)
├── screens/
│   ├── splash_screen.dart
│   ├── table_error_screen.dart # Shown when no QR scanned
│   ├── menu_screen.dart        # Main menu with search + filters
│   ├── cart_screen.dart        # Order review + place order
│   ├── order_status_screen.dart
│   └── qr_generator_screen.dart # Admin utility — print QR codes
└── widgets/
    ├── menu_item_card.dart      # Card + detail sheet
    └── cart_fab.dart            # Floating cart bar
```
