# Database Setup Guide

## Creating Supabase Project

1. Go to https://supabase.com
2. Sign up and create a new project
3. Copy your Project URL and API Key

## SQL Migrations

Run these SQL commands in Supabase SQL Editor:

### Create users table
```sql
CREATE TABLE IF NOT EXISTS public.users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  full_name text,
  phone text,
  role text CHECK (role IN ('reporter', 'executor')),
  vehicle text,
  balance_cents integer DEFAULT 0,
  withdraw_total_cents integer DEFAULT 0,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now()
);
```

### Create reports table
```sql
CREATE TABLE IF NOT EXISTS public.reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id uuid REFERENCES public.users(id) ON DELETE CASCADE,
  executor_id uuid REFERENCES public.users(id) ON DELETE SET NULL,
  status text CHECK (status IN ('new', 'in_progress', 'completed', 'verified')) DEFAULT 'new',
  comment text DEFAULT '',
  lat float NOT NULL,
  lng float NOT NULL,
  completion_lat float,
  completion_lng float,
  created_at timestamp DEFAULT now(),
  completed_at timestamp,
  verified_at timestamp,
  updated_at timestamp DEFAULT now()
);
```

### Create photos table
```sql
CREATE TABLE IF NOT EXISTS public.photos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id uuid REFERENCES public.reports(id) ON DELETE CASCADE,
  type text CHECK (type IN ('before', 'after')),
  url text NOT NULL,
  upload_date timestamp DEFAULT now()
);
```

### Create messages table
```sql
CREATE TABLE IF NOT EXISTS public.messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id uuid REFERENCES public.reports(id) ON DELETE CASCADE,
  sender_id uuid REFERENCES public.users(id) ON DELETE CASCADE,
  text text NOT NULL,
  created_at timestamp DEFAULT now()
);
```

### Create transactions table
```sql
CREATE TABLE IF NOT EXISTS public.transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES public.users(id) ON DELETE CASCADE,
  report_id uuid REFERENCES public.reports(id) ON DELETE SET NULL,
  type text CHECK (type IN ('earn', 'withdraw')),
  amount_cents integer NOT NULL,
  status text CHECK (status IN ('pending', 'completed', 'failed')) DEFAULT 'pending',
  created_at timestamp DEFAULT now(),
  processed_at timestamp
);
```

## Create Storage Buckets

In Supabase Storage section:
1. Create new bucket called `photos`
2. Make it public
3. Set policies to allow authenticated users to upload
