#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SUPABASE="${SUPABASE_BIN:-$HOME/.local/bin/supabase}"
INFO_PLIST="$ROOT/Birthmate/Resources/Info.plist"
PROJECT_NAME="${SUPABASE_PROJECT_NAME:-birthmate-app}"

cd "$ROOT"

if ! command -v "$SUPABASE" >/dev/null 2>&1; then
  echo "Supabase CLI not found. Install with:"
  echo "  curl -L https://github.com/supabase/cli/releases/latest/download/supabase_darwin_amd64.tar.gz | tar -xz"
  echo "  mv supabase ~/.local/bin/"
  exit 1
fi

echo "==> Checking Supabase login..."
if ! "$SUPABASE" projects list >/dev/null 2>&1; then
  if [[ -z "${SUPABASE_ACCESS_TOKEN:-}" ]]; then
    echo "Not logged in."
    echo
    echo "Run this in Terminal (outside Cursor), then re-run this script:"
    echo "  ~/.local/bin/supabase login"
    echo
    echo "Or create a token at https://supabase.com/dashboard/account/tokens and run:"
    echo "  SUPABASE_ACCESS_TOKEN=your_token ./scripts/setup-supabase-cloud.sh"
    exit 1
  fi
  export SUPABASE_ACCESS_TOKEN
fi

echo "==> Selecting organization..."
ORG_ID="$("$SUPABASE" orgs list --output json | /usr/bin/python3 -c "
import json, sys
orgs = json.load(sys.stdin)
if not orgs:
    raise SystemExit('No Supabase organizations found. Create one at https://supabase.com/dashboard')
print(orgs[0]['id'])
")"

EXISTING_REF="$("$SUPABASE" projects list --output json | /usr/bin/python3 -c "
import json, sys
name = '$PROJECT_NAME'
for project in json.load(sys.stdin):
    if project.get('name') == name:
        print(project['id'])
        break
" || true)"

if [[ -n "$EXISTING_REF" ]]; then
  PROJECT_REF="$EXISTING_REF"
  echo "==> Using existing project: $PROJECT_NAME ($PROJECT_REF)"
else
  DB_PASSWORD="$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 24)"
  echo "==> Creating Supabase project: $PROJECT_NAME"
  CREATE_JSON="$("$SUPABASE" projects create "$PROJECT_NAME" --org-id "$ORG_ID" --db-password "$DB_PASSWORD" --region us-east-1 --output json)"
  PROJECT_REF="$(echo "$CREATE_JSON" | /usr/bin/python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")"
  echo "    Project ref: $PROJECT_REF"
  echo "    Waiting for project to become active..."
  sleep 25
fi

echo "==> Linking local repo to project..."
"$SUPABASE" link --project-ref "$PROJECT_REF"

echo "==> Applying database migration..."
"$SUPABASE" db push

echo "==> Fetching API credentials..."
API_JSON="$("$SUPABASE" projects api-keys --project-ref "$PROJECT_REF" --output json)"
SUPABASE_URL="https://${PROJECT_REF}.supabase.co"
SUPABASE_ANON_KEY="$(echo "$API_JSON" | /usr/bin/python3 -c "
import json, sys
keys = json.load(sys.stdin)
for key in keys:
    if key.get('name') == 'anon':
        print(key['api_key'])
        break
else:
    raise SystemExit('anon key not found')
")"

echo "==> Writing credentials to Info.plist..."
/usr/libexec/PlistBuddy -c "Set :SUPABASE_URL $SUPABASE_URL" "$INFO_PLIST"
/usr/libexec/PlistBuddy -c "Set :SUPABASE_ANON_KEY $SUPABASE_ANON_KEY" "$INFO_PLIST"

echo
echo "Done! Supabase is ready for Birthmate."
echo "  URL:  $SUPABASE_URL"
echo "  Ref:  $PROJECT_REF"
echo
echo "Next steps:"
echo "  1. Rebuild and run the app in Xcode"
echo "  2. Settings -> turn on Birthday Circle toggles"
echo "  3. Open the Circle tab"
echo
echo "Note: Info.plist now contains your anon key. Do not commit it to git."
