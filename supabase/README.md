# Supabase local setup

Birthmate uses **Supabase Cloud** for Birthday Circle (Docker is not required).

## One-time setup

1. **Log in to Supabase** (in Terminal.app):

```bash
~/.local/bin/supabase login
```

2. **Create the project, run migrations, and wire the app**:

```bash
cd /Users/osagieobaretin/Birthmate
./scripts/setup-supabase-cloud.sh
```

This will:
- Create a project named `birthmate-app` (or reuse it if it exists)
- Apply `supabase/migrations/20260729000000_birthday_circle.sql`
- Write `SUPABASE_URL` and `SUPABASE_ANON_KEY` into `Birthmate/Resources/Info.plist`

3. **Rebuild the app** in Xcode and open the **Circle** tab.

## Alternative: access token

If browser login does not work in your environment:

1. Create a token at https://supabase.com/dashboard/account/tokens
2. Run:

```bash
SUPABASE_ACCESS_TOKEN=your_token ./scripts/setup-supabase-cloud.sh
```

## Local Supabase (optional)

Local `supabase start` requires **Docker Desktop**. Install Docker, then:

```bash
supabase start
supabase db reset
```

Use the local URL and anon key from `supabase status` in `Info.plist`.

## Apple Sign In (required for live Circle)

1. In Supabase Dashboard → **Authentication** → **Providers** → enable **Apple**.
2. In Apple Developer → configure Sign in with Apple for bundle ID `com.birthmate.app`.
3. Add the Apple Services ID / secret to Supabase if using web flow (native iOS uses id_token directly).

After `./scripts/setup-supabase-cloud.sh`, also run:

```bash
~/.local/bin/supabase db push
```

This applies `20260729120000_social_foundation.sql` (friends, favorites, activity, secure RLS).
