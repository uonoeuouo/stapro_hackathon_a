import os
from datetime import datetime, timezone
from typing import List, Optional, Dict, Any
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from supabase import create_client, Client
from pydantic import BaseModel
from dotenv import load_dotenv
from stapro_api_client import StaproAPIClient
from datetime import date

# 環境変数の読み込み
load_dotenv()

app = FastAPI()

# CORS設定 (Flutterアプリからのアクセスを許可)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
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
    attendance_id: Optional[int] = None
    clock_in_at: Optional[str] = None
    external_active: Optional[bool] = False

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
    # Supabase の is_ 等の挙動に依存せず、取得したレコードをコード側でチェックする。
    # これにより `NULL`、空文字、文字列 "null" のような不整合にも対応する。
    try:
        res = supabase.table("attendance_logs")\
            .select("*")\
            .eq("user_id", user_id)\
            .order("id", desc=True)\
            .limit(50)\
            .execute()
    except Exception:
        return None

    if not res.data:
        return None

    for row in res.data:
        if row is None:
            continue
        co = row.get('clock_out_at')
        if co is None or co == "" or (isinstance(co, str) and co.lower() == "null"):
            return row

    return None

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
        # コマ数はフロントエンドで計算して送信されるため、ここでは推定を行わない
        return {
            "status": "ready_to_out",
            "user_name": user['name'],
            "message": "お疲れ様です、{user['name']}さん。",
            "default_cost": user.get('default_transport_cost', 0),
            "estimated_class_count": 0,
            "transport_presets": user.get('transport_presets', []),
            "attendance_id": active_log.get('id'),
            "clock_in_at": active_log.get('clock_in_at'),
            "external_active": False,
        }
    else:
        # --- パターンA: 未出勤 -> フロントに出勤画面へ誘導（書き込みは行わない） ---
        # ここではDBや外部APIへの書き込みはせず、フロントが
        # `/api/clock-in` を実行したときに出勤処理を行う方針とする。
        response_payload = {
            "status": "ready_to_in",
            "user_name": user['name'],
            "message": f"おはようございます、{user['name']}さん。",
            "default_cost": int(user.get('default_transport_cost', 0) or 0),
            "estimated_class_count": 0,
            "transport_presets": user.get('transport_presets', []),
            "attendance_id": None,
            "clock_in_at": None,
            "external_active": False,
        }

        return response_payload

@app.post("/api/clock-in")
def clock_in(req: ClockInRequest):
    """出勤打刻"""
    user = _get_user_by_card(req.card_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # 重複チェック（既に出勤中ならエラーにするか、無視するか）
    if _get_active_log(user['id']):
        raise HTTPException(status_code=400, detail="既に出勤済みです")
    
    # DB登録（ローカル）
    now_iso = datetime.now(timezone.utc).isoformat()
    data = {
        "user_id": user['id'],
        "clock_in_at": now_iso
    }
    insert_res = supabase.table("attendance_logs").insert(data).execute()

    # 可能なら Stapro に勤怠を作成する（失敗してもローカルは残す）
    stapro_url = os.getenv("STAPRO_API_URL")
    stapro_token = os.getenv("STAPRO_API_TOKEN")
    external_created = False
    try:
        staff_id = user.get('stapro_staff_id') or user.get('staff_id') or user.get('id')
        if stapro_url and stapro_token and staff_id:
            client = StaproAPIClient(base_url=stapro_url, api_token=stapro_token)
            work_day = date.today().isoformat()
            school_id = user.get('stapro_school_id') or user.get('default_school_id') or 1
            commuting_costs = int(user.get('default_transport_cost', 0) or 0)
            client.create_attendance(
                staff_id=int(staff_id),
                work_day=work_day,
                school_id=int(school_id),
                commuting_costs=commuting_costs,
                another_time=0.0,
                total_lesson=0,
                lesson_ids=[],
            )
            external_created = True
    except Exception as e:
        print(f"Stapro create_attendance failed on clock-in: {e}")

    # レスポンスに挿入結果を含める
    resp = {"message": "出勤を記録しました", "external_created": external_created}
    try:
        resp['attendance_id'] = insert_res.data[0].get('id')
        resp['clock_in_at'] = insert_res.data[0].get('clock_in_at')
    except Exception:
        resp['attendance_id'] = None
        resp['clock_in_at'] = now_iso

    return resp

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
    external_created = False
    try:
        # まず System A への同期（任意）
        try:
            _sync_system_a(user['name'], req.transport_cost, req.class_count)
        except Exception as e:
            print(f"System A sync failed: {e}")

        # Stapro に勤怠を作成（または外部に送る処理）
        stapro_url = os.getenv("STAPRO_API_URL")
        stapro_token = os.getenv("STAPRO_API_TOKEN")
        staff_id = user.get('stapro_staff_id') or user.get('staff_id') or user.get('id')
        if stapro_url and stapro_token and staff_id:
            client = StaproAPIClient(base_url=stapro_url, api_token=stapro_token)
            work_day = date.today().isoformat()
            school_id = user.get('stapro_school_id') or user.get('default_school_id') or 1
            # 退勤時に交通費・授業数を伝える
            client.create_attendance(
                staff_id=int(staff_id),
                work_day=work_day,
                school_id=int(school_id),
                commuting_costs=int(req.transport_cost),
                another_time=0.0,
                total_lesson=int(req.class_count),
                lesson_ids=[],
            )
            external_created = True
    except Exception as e:
        print(f"Stapro create_attendance failed on clock-out: {e}")

    return {"message": "退勤と業務報告が完了しました", "external_created": external_created}