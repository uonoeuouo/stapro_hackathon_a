# Windows用 APIクライアント生成スクリプト (PowerShell)

# 1. バックエンドが起動しているか確認（起動してないとjson取れないから）
Write-Host "Fetching OpenAPI spec from backend..."

# 2. 自動生成コマンド実行
openapi-generator generate `
  -i http://127.0.0.1:8000/openapi.json `
  -g dart-dio `
  -o ./frontend_api_client `
  --additional-properties=pubName=openapi

Write-Host "Done! API client generated in ./frontend_api_client"