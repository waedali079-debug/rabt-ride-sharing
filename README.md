# Rabt - منصة النقل الذكية 🚗

منصة نقل متعددة القطاعات تربط الزبائن بالسائقين عبر تطبيق ذكي مع نظام دفع آمن وتتبع مباشر.

## الميزات الرئيسية

- **9 قطاعات**: ركاب، غاز، مياه، شحن صغير، شاحنات، ونشات، آليات، شحن كبير، خدمات خاصة
- **تتبع مباشر**: تحديثات موقع السائق في الوقت الحقيقي عبر WebSocket
- **دفع آمن**: نظام Escrow مع تشفير البيانات الحساسة
- **RLS**: Row-Level Security لحماية البيانات
- **نظام التلغيب**: Gamification مع شجرة تنمو مع كل رحلة

## هيكل المشروع

```
rabt-ride-sharing/
├── backend/          # Node.js/Express API
├── mobile/           # Flutter Client
├── database/         # SQL Schema, Migrations
├── docs/             # التوثيق
└── README.md
```

## المتطلبات

- Node.js >= 18.0.0
- Flutter SDK >= 3.0.0
- Supabase Account
- Render Account (للنشر)

## البدء السريع

### 1. استنساخ المشروع
```bash
git clone https://github.com/your-username/rabt-ride-sharing.git
cd rabt-ride-sharing
```

### 2. إعداد Backend
```bash
cd backend
cp .env.example .env
# عدّل ملف .env بإعدادات Supabase الخاصة بك
npm install
npm run dev
```

### 3. إعداد Flutter Client
```bash
cd mobile
flutter pub get
flutter run
```

### 4. إعداد قاعدة البيانات
1. أنشئ مشروع Supabase جديد
2. شغّل ملف `database/schema.sql` في SQL Editor
3. انسخ مفاتيح Supabase إلى ملف `.env`

## التكاملات

### Codespaces (للتطوير)
1. افتح المشروع على GitHub
2. اضغط "Code" > "Codespaces" > "New codespace"
3. سيعمل التلقائياً بعد الإنشاء

### Render (للنشر)
1. اربط GitHub Repo مع Render
2. استخدم `backend/render.yaml` للتكوين التلقائي
3. اضبط Environment Variables في Render Dashboard

## API Endpoints

### Auth
- `POST /api/v1/users/register` - تسجيل مستخدم جديد
- `POST /api/v1/users/login` - تسجيل الدخول عبر OTP
- `GET /api/v1/users/profile` - جلب الملف الشخصي

### Trips
- `GET /api/v1/trips` - جلب الرحلات
- `POST /api/v1/trips` - إنشاء رحلة جديدة
- `POST /api/v1/trips/:id/accept` - قبول الرحلة (للسائقين)
- `POST /api/v1/trips/:id/complete` - إكمال الرحلة
- `POST /api/v1/trips/:id/cancel` - إلغاء الرحلة

### Payments
- `POST /api/v1/payments` - إنشاء دفعة جديدة
- `GET /api/v1/payments/:id` - جلب تفاصيل الدفعة
- `PATCH /api/v1/payments/:id/status` - تحديث حالة الدفعة

### Sectors
- `GET /api/v1/sectors` - جلب جميع القطاعات
- `GET /api/v1/sectors/:code` - جلب قطاع محدد

## الأمان

- تشفير الرقم القومي بـ AES-256-GCM
- JWT Authentication عبر Supabase Auth
- Row-Level Security على جميع الجداول
- Helmet.js لحماية HTTP Headers
- CORS للطلبات المصرح بها

## الترخيص

هذا مشروع خاص - جميع الحقوق محفوظة.
