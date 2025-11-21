#!/bin/bash

# 1. バックエンドが起動しているか確認（起動してないとjson取れないから）
echo "Fetching OpenAPI spec from backend..."

# 2. 自動生成コマンド実行
# (注意: Mac/Linux用。Windowsの場合はパスの書き方が少し変わる)
openapi-generator generate \
  -i http://127.0.0.1:8000/openapi.json \
  -g dart-dio \
  -o ./frontend/lib/api \
  --additional-properties=pubName=openapi

echo "Done! API client generated in ./frontend/lib/api"