# hackathon_net

UrbanScore Flutter app with Supabase-based account authentication.

## Supabase setup

1. Create a Supabase project.
2. In Supabase Auth, enable Email authentication.
3. Copy your project URL and anon key from the API settings.
4. Open the SQL editor in Supabase and run [profiles.sql](/Users/aliserromankul/Desktop/arsen/hackathon_net/supabase/profiles.sql).

This table stores the app role for each authenticated user.

Available roles:

- `resident`
- `builder`
- `admin`

Security note:

- regular sign-up allows only `resident` and `builder`
- `admin` must be assigned manually in Supabase

## Run the app

```bash
flutter pub get
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

If these values are missing, the app shows a setup screen instead of the login form.

## What was added

- email/password sign in and sign up via Supabase
- auth session gate before entering the main app
- account tab with current user info and sign out
- role-based profile storage in `public.profiles`
- account types: resident, builder, administrator

## How to assign administrator

After a user registers, update their row in `public.profiles`:

```sql
update public.profiles
set role = 'admin'
where email = 'user@example.com';
```
