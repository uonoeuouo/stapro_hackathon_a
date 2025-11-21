import os
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from supabase import create_client, Client
from pydantic import BaseModel
from dotenv import load_dotenv

# 環境変数の読み込み
load_dotenv()

app = FastAPI()

# CORS設定 (Flutterアプリからのアクセスを許可)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 本番では特定のオリジンに絞るべきだがハッカソンならこれでOK
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Supabase接続
url: str = os.environ.get("SUPABASE_URL")
key: str = os.environ.get("SUPABASE_KEY")

# 環境変数が読み込めてるかチェック
if not url or not key:
    raise ValueError("Supabase credentials not found in .env")

supabase: Client = create_client(url, key)

# --- 型定義 ---
class ScanRequest(BaseModel):
    card_id: str

# --- エンドポイント ---
@app.get("/")
def read_root():
    return {"message": "Backend is running!testtest"}

@app.post("/api/scan")
def scan_card(req: ScanRequest):
    # DBからユーザー検索
    response = supabase.table("users").select("*").eq("card_id", req.card_id).execute()
    
    if not response.data:
        # 未登録の場合
        raise HTTPException(status_code=404, detail="User not found")
        
    user = response.data[0]
    
    # 仮の実装: とりあえずユーザー名を返す
    return {
        "status": "ready_to_in", # ロジックは後で書くとして一旦固定
        "user_name": user["name"],
        "message": f"こんにちは、{user['name']}さん"
    }