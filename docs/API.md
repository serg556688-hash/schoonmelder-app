# Schoonmelder Backend API

## Endpoints

### Reports

#### GET /api/reports
Получить все отчёты

**Query Parameters:**
- `status` (optional): 'new' | 'in_progress' | 'completed' | 'verified'

#### GET /api/reports/:id
Получить определённый отчёт

#### POST /api/reports
Создать новый отчёт

**Body:**
```json
{
  "reporter_id": "uuid",
  "comment": "string (optional)",
  "lat": 52.52,
  "lng": 13.40
}
```

#### PATCH /api/reports/:id
Обновить статус отчёта

**Body:**
```json
{
  "status": "in_progress",
  "executor_id": "uuid (optional)",
  "completion_lat": 52.52,
  "completion_lng": 13.40
}
```

### Messages

#### GET /api/reports/:reportId/messages
Получить все сообщения для отчёта

#### POST /api/reports/:reportId/messages
Отправить сообщение

**Body:**
```json
{
  "sender_id": "uuid",
  "text": "string"
}
```

### Photos

#### POST /api/upload/photo
Загрузить фото

**Body:**
```json
{
  "reportId": "uuid",
  "photoBase64": "data:image/jpeg;base64,...",
  "photoType": "before" | "after"
}
```

### Users

#### GET /api/users/:id
Получить профиль пользователя

#### PATCH /api/users/:id
Обновить профиль

**Body:**
```json
{
  "full_name": "string",
  "phone": "string",
  "vehicle": "foot" | "bike" | "ebike" | "scooter" | "car"
}
```

### Transactions

#### GET /api/users/:userId/transactions
Получить историю транзакций пользователя

#### POST /api/transactions/withdraw
Создать заявку на вывод средств

**Body:**
```json
{
  "user_id": "uuid",
  "amount_cents": 5000,
  "payment_method": "card" | "paypal" | "gift_card"
}
```
