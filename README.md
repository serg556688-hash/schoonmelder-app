# Schoonmelder - Полноценное приложение для отчётов о мусоре

## 📱 Описание

Полнофункциональное веб-приложение для отчётов о загрязнении окружающей среды с системой вознаграждений для исполнителей.

## 🎯 Функциональность

### Для заказчиков (Reporters)
- 📸 Отправка фото мусора с геолокацией
- 💬 Комментарии к отчётам
- 📊 История всех отчётов
- 💰 Система бонусов (5¢ за каждое фото)
- 💵 Вывод средств (карта, PayPal, подарочные карты)
- 💬 Чат с исполнителем

### Для исполнителей (Executors)
- 📋 Список активных заданий
- 🗺️ Навигация с расчётом расстояния и времени
- 🚶 Выбор транспорта (пешком, велосипед, электровелик, скутер, автомобиль)
- 📸 Фото после выполнения работы
- ✅ Подтверждение выполнения
- 💰 Доход (50¢ за каждое выполненное задание)
- 🔍 Геоверификация (проверка что работа выполнена в нужном месте)

## 🏗️ Архитектура

```
schoonmelder-app/
├── frontend/              # React + Vite
│   ├── src/
│   │   ├── components/   # React компоненты
│   │   ├── pages/        # Страницы
│   │   ├── hooks/        # Custom hooks
│   │   ├── utils/        # Утилиты
│   │   ├── styles/       # CSS стили
│   │   └── App.jsx       # Main component
│   └── package.json
├── backend/               # Node.js + Express
│   ├── src/
│   │   ├── routes/       # API routes
│   │   ├── middleware/   # Express middleware
│   │   ├── models/       # Database models
│   │   ├── services/     # Business logic
│   │   ├── controllers/  # Request handlers
│   │   └── index.js      # Server entry point
│   └── package.json
├── docker-compose.yml     # Docker контейнеры
└── README.md
```

## 🔧 Технологический стек

### Frontend
- **React 18** - UI библиотека
- **Vite** - Build tool
- **Supabase JS Client** - Real-time database
- **Tailwind CSS** - Стили
- **Lucide React** - Иконки

### Backend
- **Node.js** - Runtime
- **Express** - Web framework
- **Supabase** - Database & Auth & Storage
- **JWT** - Authentication
- **Multer** - File uploads
- **Cors** - Cross-origin requests

### Database
- **PostgreSQL** (Supabase) - Основная база
- **Supabase Storage** - Хранение фото
- **Supabase Realtime** - Синхронизация в реальном времени

## 🚀 Запуск локально

### Требования
- Node.js 18+
- npm или yarn
- Supabase аккаунт

### Установка

1. **Клонируем репозиторий**
```bash
git clone https://github.com/serg556688-hash/schoonmelder-app.git
cd schoonmelder-app
```

2. **Устанавливаем зависимости**
```bash
npm install
```

3. **Создаём Supabase проект**
- Идём на https://supabase.com
- Создаём новый проект
- Копируем URL и API ключ

4. **Создаём .env файлы**

**frontend/.env**
```
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your_anon_key
```

**backend/.env**
```
PORT=3000
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
JWT_SECRET=your_jwt_secret
NODE_ENV=development
```

5. **Запускаем приложение**
```bash
npm run dev
```

Frontend будет доступен на http://localhost:5173
Backend API на http://localhost:3000

## 📊 Структура БД

### Таблица users
```sql
id (uuid, PK)
email (text, unique)
full_name (text)
phone (text)
role (text) - 'reporter' или 'executor'
vehicle (text) - тип транспорта
balance_cents (integer) - баланс в центах
withdraw_total_cents (integer) - всего выведено
created_at (timestamp)
updated_at (timestamp)
```

### Таблица reports
```sql
id (uuid, PK)
reporter_id (uuid, FK -> users)
executor_id (uuid, FK -> users)
status (text) - 'new', 'in_progress', 'completed', 'verified'
comment (text)
lat (float) - широта места отчёта
lng (float) - долгота места отчёта
completion_lat (float) - широта после выполнения
completion_lng (float) - долгота после выполнения
created_at (timestamp)
completed_at (timestamp)
verified_at (timestamp)
```

### Таблица photos
```sql
id (uuid, PK)
report_id (uuid, FK -> reports)
type (text) - 'before' или 'after'
url (text) - путь в Supabase Storage
upload_date (timestamp)
```

### Таблица messages
```sql
id (uuid, PK)
report_id (uuid, FK -> reports)
sender_id (uuid, FK -> users)
text (text)
created_at (timestamp)
```

### Таблица transactions
```sql
id (uuid, PK)
user_id (uuid, FK -> users)
report_id (uuid, FK -> reports)
type (text) - 'earn', 'withdraw'
amount_cents (integer)
status (text) - 'pending', 'completed', 'failed'
created_at (timestamp)
processed_at (timestamp)
```

## 🔐 Безопасность

- ✅ JWT авторизация для всех API endpoints
- ✅ Валидация данных на backend
- ✅ Защита от XSS атак
- ✅ CORS настройки
- ✅ Rate limiting
- ✅ SQL injection protection (через Supabase)
- ✅ Геоверификация заданий
- ✅ HTTPS только в production

## 📈 Масштабируемость

- Real-time синхронизация через WebSocket (Supabase Realtime)
- CDN для статических файлов (через Vercel)
- Автоскейлинг backend (Render/Railway)
- Оптимизированные database queries
- Кеширование на frontend (React Query)

## 🚢 Развёртывание

### Vercel (Frontend)
1. Push в GitHub
2. Connectить Vercel
3. Задать environment variables
4. Auto-deploy при каждом push

### Render/Railway (Backend)
1. Connectить GitHub репозиторий
2. Задать environment variables
3. Deploy
4. Автоматические обновления при push

## 📝 Лицензия

MIT

## 👨‍💻 Разработка

Для локальной разработки:

```bash
# Клонируем
git clone https://github.com/serg556688-hash/schoonmelder-app.git
cd schoonmelder-app

# Устанавливаем зависимости
npm install

# Запускаем development сервер
npm run dev

# Для production
npm run build
npm run start
```

## 📞 Поддержка

Если у вас есть вопросы или проблемы, создавайте issues в этом репозитории.
