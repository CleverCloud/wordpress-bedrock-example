#!/bin/bash
# Create the S3 bucket on Cellar

command -v s3cmd >/dev/null || pip install s3cmd

# Keep the credentials out of the repository
S3CFG=$(mktemp)
trap 'rm -f "$S3CFG"' EXIT

cat > "$S3CFG" << EOF
[default]
access_key = $CELLAR_ADDON_KEY_ID
secret_key = $CELLAR_ADDON_KEY_SECRET
host_base = $CELLAR_ADDON_HOST
host_bucket = $CELLAR_ADDON_HOST
use_https = True
EOF

# Skip creation when the bucket already exists, e.g. on redeploys
if s3cmd ls "s3://$CELLAR_ADDON_BUCKET" -c "$S3CFG" >/dev/null 2>&1; then
  echo "Bucket s3://$CELLAR_ADDON_BUCKET already exists"
else
  s3cmd mb "s3://$CELLAR_ADDON_BUCKET" -c "$S3CFG"
fi
