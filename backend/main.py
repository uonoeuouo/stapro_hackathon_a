import os
from datetime import datetime, timedelta, timezone
from typing import List, Optional, Dict, Any
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

class ScanResponse(BaseModel):
    status: str  # "ready_to_in", "ready_to_out", "finished"
    user_name: str
    message: str
    default_cost: Optional[int] = 0
    estimated_class_count: Optional[int] = 0
    transport_presets: Optional[List[Dict[str, Any]]] = []

class ClockInRequest(BaseModel):
    card_id: str

class ClockOutRequest(BaseModel):
    card_id: str
    transport_cost: int
    class_count: int
    is_auto_submit: bool = False


#--- ヘルパー関数 ---
def _get_user_by_card(card_id: str):
    """カードIDからユーザーを検索する"""
    res = supabase.table("users").select("*").eq("card_id", card_id).execute()
    if not res.data:
        return None
    return res.data[0]

def _get_active_log(user_id: str):
    """現在出勤中（退勤していない）のログを取得する"""
    res = supabase.table("attendance_logs")\
        .select("*")\
        .eq("user_id", user_id)\
        .is_("clock_out_at", "null")\
        .execute()
    if res.data:
        return res.data[0]
    return None

def _estimate_classes(clock_in_at_str: str) -> int:
    """出勤時刻から現在のコマ数を推定する"""
    if not clock_in_at_str:
        return 0
    
    # 文字列をdatetimeに変換 (SupabaseはISO8601形式で返してくる)
    clock_in = datetime.fromisoformat(clock_in_at_str.replace('Z', '+00:00'))
    now = datetime.now(timezone.utc)
    
    # 滞在時間（分）
    duration_min = (now - clock_in).total_seconds() / 60
    
    # 【ロジック】スクールの規定に合わせて調整してください
    if duration_min < 60:
        return 0
    elif duration_min < 150: # 2.5時間未満 = 1コマ
        return 1
    elif duration_min < 240: # 4時間未満 = 2コマ
        return 2
    else:
        return 3 # それ以上は3コマ

def _sync_system_a(user_name: str, transport: int, classes: int):
    # TODO: 余裕があればここにシステムA連携を書く
    print(f"[Mock] System A連携: {user_name} / {transport}円 / {classes}コマ")
    return True



# --- エンドポイント ---
@app.get("/")
def health_check():
    return {"status": "ok", "message": "Backend is running"}

@app.post("/api/scan", response_model=ScanResponse)
def scan_card(req: ScanRequest):
    """カードをスキャンした時の状態判定"""
    
    # 1. ユーザー特定
    user = _get_user_by_card(req.card_id)
    if not user:
        raise HTTPException(status_code=404, detail="未登録のカードです")
    
    # 2. 現在の状態を確認（出勤中か？）
    active_log = _get_active_log(user['id'])
    
    if active_log:
        # --- パターンB: 出勤中 -> 退勤画面へ誘導 ---
        estimated = _estimate_classes(active_log['clock_in_at'])
        
        return {
            "status": "ready_to_out",
            "user_name": user['name'],
            "message": "お疲れ様でした。業務報告をお願いします。",
            "default_cost": user.get('default_transport_cost', 0),
            "estimated_class_count": estimated,
            "transport_presets": user.get('transport_presets', [])
        }
    else:
        # --- パターンA: 未出勤 -> 出勤処理へ誘導 ---
        return {
            "status": "ready_to_in",
            "user_name": user['name'],
            "message": f"おはようございます、{user['name']}さん。",
            "default_cost": 0,
            "estimated_class_count": 0,
            "transport_presets": []
        }

@app.post("/api/clock-in")
def clock_in(req: ClockInRequest):
    """出勤打刻"""
    user = _get_user_by_card(req.card_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # 重複チェック（既に出勤中ならエラーにするか、無視するか）
    if _get_active_log(user['id']):
        raise HTTPException(status_code=400, detail="既に出勤済みです")
    
    # DB登録
    data = {
        "user_id": user['id'],
        "clock_in_at": datetime.now(timezone.utc).isoformat()
    }
    supabase.table("attendance_logs").insert(data).execute()
    
    return {"message": "出勤を記録しました"}

@app.post("/api/clock-out")
def clock_out(req: ClockOutRequest):
    """退勤打刻 + 外部連携"""
    user = _get_user_by_card(req.card_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    active_log = _get_active_log(user['id'])
    if not active_log:
        raise HTTPException(status_code=400, detail="出勤記録が見つかりません")
    
    # 1. DB更新 (退勤時間と実績を入力)
    update_data = {
        "clock_out_at": datetime.now(timezone.utc).isoformat(),
        "transport_cost": req.transport_cost,
        "class_count": req.class_count,
        "is_auto_submit": req.is_auto_submit
    }
    
    supabase.table("attendance_logs")\
        .update(update_data)\
        .eq("id", active_log['id'])\
        .execute()
    
    # 2. 外部システム連携
    # ここでエラーが起きてもDBの退勤記録は残るようにしている
    try:
        _sync_system_a(user['name'], req.transport_cost, req.class_count)
    except Exception as e:
        print(f"System A sync failed: {e}")
    
    return {"message": "退勤と業務報告が完了しました"}