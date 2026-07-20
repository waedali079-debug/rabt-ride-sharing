# Rabt (ربط) - Session Log & Quick Reference

## Project Overview
Multi-sector ride-sharing platform (9 sectors) with Flutter app, Node.js backend, Supabase database, and real-time GPS tracking.

---

## Quick Connect
> **Credentials saved in `.session.env` (local, gitignored)**
> Run: `source .session.env` to load them

---

## Completed Features (15 Commits)

### ✅ SCR-001: Backend Setup
- Supabase connection via Prisma ORM (v7.8.0)
- 9 database tables with PostGIS
- `rabt_` prefix for all tables
- DB columns: `sector_code`, `name_ar`, `name_en`, `color_code`, `icon_name`

### ✅ SCR-002: Landing Hub (Sector Selection)
- `landing_hub_screen.dart` - 9-sector responsive grid
- Responsive: 3 cols (phone), 4 cols (tablet), 5 cols (desktop)

### ✅ SCR-003: Auth Flow (Phone OTP)
- Country picker: `country_picker: ^2.0.28` (100+ countries)
- Favorites: SA, AE, EG, KW, QA, BH, OM
- `auth_service.dart` - OTP send/verify via Supabase Auth

### ✅ SCR-004: Trip Request
- OpenStreetMap (`flutter_map: ^6.1.0`) + GPS (`geolocator: ^10.1.0`)
- Auto-navigates to tracking on success

### ✅ SCR-005: WebSocket Tracking Server
- `backend/src/tracking-server.js` - Socket.io on port 8080
- Events: `join_trip`, `location_update`, `status_update`, `cancel_trip`

### ✅ SCR-104: Live Tracking Screen
- `tracking_screen.dart` - Real-time driver tracking
- `tracking_service.dart` - WebSocket client
- Bottom card: status, call/message/SOS buttons, cancel with confirmation

### ✅ CI/CD + Permissions
- GitHub Actions auto-build on push
- INTERNET, ACCESS_NETWORK_STATE, Location permissions

---

## File Structure

```
rabt/
├── lib/
│   ├── main.dart                              # App entry + Supabase init
│   ├── core/services/
│   │   ├── auth_service.dart                  # Phone OTP auth
│   │   └── tracking_service.dart              # WebSocket client
│   └── features/
│       ├── auth/presentation/
│       │   ├── phone_input_screen.dart        # Country picker + phone
│       │   └── otp_verification_screen.dart   # OTP verify
│       ├── sectors/
│       │   ├── domain/sector_model.dart       # Sector model
│       │   ├── data/sector_service.dart       # Fetch from Supabase
│       │   └── presentation/landing_hub_screen.dart
│       └── trips/
│           ├── data/trip_service.dart
│           └── presentation/
│               ├── request_trip_screen.dart    # Map + request
│               └── tracking_screen.dart        # Live tracking
├── backend/
│   ├── src/tracking-server.js                 # WebSocket server
│   └── prisma/schema.prisma                   # 9 models
├── database/schema.sql                        # V31 schema
└── pubspec.yaml
```

---

## Package Versions
```yaml
supabase_flutter: ^2.8.0
country_picker: ^2.0.28
socket_io_client: ^2.0.3+1
flutter_map: ^6.1.0
geolocator: ^10.1.0
latlong2: ^0.9.1
google_fonts: ^6.1.0
```

---

## Key Decisions
- **flutter_map** over google_maps_flutter (zero API cost)
- **country_picker** for global phone support
- **Debug signing** for development
- **Package name**: `rabt` (not `rabt_app`)
- **Supabase key**: `sb_publishable_...` format (v2.13+)

---

## Next Steps (SCR-105+)

### 🔴 SCR-105: Driver App
- Accept/decline trip requests
- Update driver location via WebSocket
- Trip status updates
- Driver earnings screen

### 🔴 SCR-106: Payment & Rating
- Payment method selection
- Trip completion flow
- Rating system

### 🔴 SCR-107: Push Notifications
- FCM integration
- Trip alerts to drivers

### 🔴 Production
- Deploy backend to Render
- Set up Twilio for SMS
- Enable Phone Auth in Supabase Dashboard
- Release signing key

---

## Known Issues
1. **APK Download**: GitHub Actions artifacts require GitHub login to download
2. **WebSocket**: Tracking server needs to be running on port 8080
3. **SMS**: Supabase needs Twilio configured for global SMS

---

*Last updated: 2026-07-19*
*Session: 1*
*Status: SCR-104 complete → Next: SCR-105 (Driver App)*
