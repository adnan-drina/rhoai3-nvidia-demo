#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load environment
if [[ -f "$REPO_ROOT/.env" ]]; then
    set -a; source "$REPO_ROOT/.env"; set +a
fi

# Verify cluster guard
if [[ -z "${RHOAI_EXPECTED_API_SERVER:-}" ]]; then
    echo "ERROR: Set RHOAI_EXPECTED_API_SERVER in .env before running."
    exit 1
fi
CURRENT_SERVER=$(oc whoami --show-server 2>/dev/null || true)
if [[ -z "$CURRENT_SERVER" ]] || [[ "$CURRENT_SERVER" != *"$RHOAI_EXPECTED_API_SERVER"* ]]; then
    echo "ERROR: Current API server does not match RHOAI_EXPECTED_API_SERVER."
    exit 1
fi

echo "=== Stage 110: Demo Access Setup ==="

ADMIN_USER="ai-admin"
DEV_USER="ai-developer"
RESEARCHER_USER="ai-researcher"
HTPASSWD_SECRET="rhoai-demo-users-htpasswd"
IDP_NAME="rhoai-demo-htpasswd"
ADMIN_GROUP="rhoai-demo-admins"
DEV_GROUP="rhoai-demo-users"

# Generate passwords when unset and persist them to .env (gitignored).
gen_pw() { LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 20; }
if [[ -z "${AI_ADMIN_PASSWORD:-}" ]]; then
    AI_ADMIN_PASSWORD="$(gen_pw)"
    echo "AI_ADMIN_PASSWORD=$AI_ADMIN_PASSWORD" >> "$REPO_ROOT/.env"
    echo "Generated AI_ADMIN_PASSWORD (appended to .env)"
fi
if [[ -z "${AI_DEVELOPER_PASSWORD:-}" ]]; then
    AI_DEVELOPER_PASSWORD="$(gen_pw)"
    echo "AI_DEVELOPER_PASSWORD=$AI_DEVELOPER_PASSWORD" >> "$REPO_ROOT/.env"
    echo "Generated AI_DEVELOPER_PASSWORD (appended to .env)"
fi
if [[ -z "${AI_RESEARCHER_PASSWORD:-}" ]]; then
    AI_RESEARCHER_PASSWORD="$(gen_pw)"
    echo "AI_RESEARCHER_PASSWORD=$AI_RESEARCHER_PASSWORD" >> "$REPO_ROOT/.env"
    echo "Generated AI_RESEARCHER_PASSWORD (appended to .env)"
fi

echo "--- htpasswd secret"
HTPASSWD_FILE=$(mktemp)
CR_JSON=$(mktemp)
trap 'rm -f "$HTPASSWD_FILE" "$CR_JSON"' EXIT
htpasswd -c -b -B "$HTPASSWD_FILE" "$ADMIN_USER" "$AI_ADMIN_PASSWORD" >/dev/null 2>&1
htpasswd -b -B "$HTPASSWD_FILE" "$DEV_USER" "$AI_DEVELOPER_PASSWORD" >/dev/null 2>&1
htpasswd -b -B "$HTPASSWD_FILE" "$RESEARCHER_USER" "$AI_RESEARCHER_PASSWORD" >/dev/null 2>&1
oc create secret generic "$HTPASSWD_SECRET" -n openshift-config \
    --from-file=htpasswd="$HTPASSWD_FILE" \
    --dry-run=client -o yaml | oc apply -f -

echo "--- OAuth identity provider (merged, preserves existing providers)"
oc get oauth cluster -o json > "$CR_JSON"
python3 - "$IDP_NAME" "$HTPASSWD_SECRET" "$CR_JSON" <<'EOF' | oc apply -f -
import json, sys
name, secret, path = sys.argv[1], sys.argv[2], sys.argv[3]
oauth = json.load(open(path))
oauth.pop("status", None)
for k in ("resourceVersion", "uid", "generation", "creationTimestamp", "managedFields"):
    oauth["metadata"].pop(k, None)
idps = oauth.setdefault("spec", {}).setdefault("identityProviders", []) or []
idps = [p for p in idps if p.get("name") != name]
idps.append({
    "name": name,
    "mappingMethod": "claim",
    "type": "HTPasswd",
    "htpasswd": {"fileData": {"name": secret}},
})
oauth["spec"]["identityProviders"] = idps
json.dump(oauth, sys.stdout)
EOF

echo "--- Groups"
for g in "$ADMIN_GROUP" "$DEV_GROUP"; do
    oc get group "$g" >/dev/null 2>&1 || oc adm groups new "$g"
done
oc adm groups add-users "$ADMIN_GROUP" "$ADMIN_USER"
oc adm groups add-users "$DEV_GROUP" "$DEV_USER" "$RESEARCHER_USER"

echo "--- RHOAI Auth CR group wiring (when RHOAI is installed)"
if oc get auth.services.platform.opendatahub.io auth >/dev/null 2>&1; then
    oc get auth.services.platform.opendatahub.io auth -o json > "$CR_JSON"
    python3 - "$ADMIN_GROUP" "$DEV_GROUP" "$CR_JSON" <<'EOF' | oc apply -f -
import json, sys
admin_g, dev_g, path = sys.argv[1], sys.argv[2], sys.argv[3]
auth = json.load(open(path))
auth.pop("status", None)
for k in ("resourceVersion", "uid", "generation", "creationTimestamp", "managedFields"):
    auth["metadata"].pop(k, None)
spec = auth.setdefault("spec", {})
for key, group in (("adminGroups", admin_g), ("allowedGroups", dev_g)):
    groups = spec.setdefault(key, [])
    if group not in groups:
        groups.append(group)
json.dump(auth, sys.stdout)
EOF
else
    echo "NOTE: RHOAI Auth CR not found yet; re-run after the DataScienceCluster is Ready."
fi

echo "=== Demo access setup complete. Users: $ADMIN_USER, $DEV_USER, $RESEARCHER_USER (passwords in .env) ==="
