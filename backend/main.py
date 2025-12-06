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
    stapro_staff_id: Optional[int] = None

class ClockInRequest(BaseModel):
    card_id: str

class ClockOutRequest(BaseModel):
    card_id: str
    transport_cost: int
    class_count: int
    is_auto_submit: bool = False
    lesson_ids: Optional[List[int]] = None


#--- 型定義 (追加モデル) ---
class RegisterCardRequest(BaseModel):
    card_id: str
    stapro_email: str
    stapro_password: str
    default_transport_cost: Optional[int] = None
    default_school_id: Optional[int] = None
    transport_presets: Optional[List[Dict[str, Any]]] = None


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


def _safe_int(v: Any) -> Optional[int]:
    """Safely convert value to int, returning None on invalid input."""
    try:
        if v is None:
            return None
        if isinstance(v, int):
            return v
        s = str(v).strip()
        if s == "":
            return None
        # handle numeric strings and floats represented as strings
        return int(float(s))
    except Exception:
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
            "message": f"お疲れ様です、{user['name']}さん。",
            "default_cost": user.get('default_transport_cost', 0),
            "estimated_class_count": 0,
            "transport_presets": user.get('transport_presets', []),
            "attendance_id": active_log.get('id'),
            "clock_in_at": active_log.get('clock_in_at'),
            "stapro_staff_id": _safe_int(user.get('stapro_staff_id')) if user.get('stapro_staff_id') is not None else None,
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
            "stapro_staff_id": _safe_int(user.get('stapro_staff_id')) if user.get('stapro_staff_id') is not None else None,
        }
        return response_payload


@app.post("/api/register-card")
def register_card(req: RegisterCardRequest):
    """新規カードを登録する。Stapro にログインしてスタッフ情報を取得し、
    ローカル DB の `users` テーブルに `card_id` を紐付ける。
    リクエストには Stapro のログイン情報を含める必要がある。
    """
    stapro_url = os.getenv("STAPRO_API_URL")
    stapro_token = os.getenv("STAPRO_API_TOKEN")
    if not stapro_url or not stapro_token:
        raise HTTPException(status_code=500, detail="Stapro configuration missing")

    client = StaproAPIClient(base_url=stapro_url, api_token=stapro_token)

    # 1) Stapro にログインしてスタッフ情報を取得
    try:
        staff = client.authenticate(req.stapro_email, req.stapro_password)
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Stapro authentication failed: {e}")

    # staff は dict を想定
    staff_id = staff.get('id')
    staff_email = staff.get('email') or req.stapro_email
    # スタッフ名は last_name/first_name があれば結合
    staff_name = None
    try:
        last = staff.get('last_name') or ''
        first = staff.get('first_name') or ''
        staff_name = (last + ' ' + first).strip() or staff.get('name') or staff_email
    except Exception:
        staff_name = staff_email

    # 2) 既存ユーザーを検索（stapro_staff_id または email）
    existing = None
    try:
        if staff_id is not None:
            res = supabase.table('users').select('*').eq('stapro_staff_id', int(staff_id)).execute()
            if res.data:
                existing = res.data[0]
        if existing is None:
            res2 = supabase.table('users').select('*').eq('email', staff_email).execute()
            if res2.data:
                existing = res2.data[0]
    except Exception:
        # 検索エラーが起きても先に進める（insert 時に重複が起きれば DB 側で確認）
        existing = None

    # Build payload from Stapro info and request — then sanitize by allowed columns
    user_payload = {
        'name': staff_name,
        'email': staff_email,
        'card_id': req.card_id,
    }
    if req.default_transport_cost is not None:
        user_payload['default_transport_cost'] = int(req.default_transport_cost)
    if req.transport_presets is not None:
        user_payload['transport_presets'] = req.transport_presets
    # include stapro_staff_id when available and integer
    stapro_staff_int = None
    try:
        stapro_staff_int = int(staff_id) if staff_id is not None else None
    except Exception:
        stapro_staff_int = None
    if stapro_staff_int is not None:
        user_payload['stapro_staff_id'] = stapro_staff_int

    # Supabase `users` table columns (as provided):
    # id, card_id, name, default_transport_cost, transport_presets, created_at, email
    allowed_cols = {'card_id', 'name', 'default_transport_cost', 'transport_presets', 'email', 'stapro_staff_id'}
    sanitized_payload: Dict[str, Any] = {k: v for k, v in user_payload.items() if k in allowed_cols and v is not None}

    # 3) insert or update
    try:
        if existing:
            # update existing user (only allowed columns)
            supabase.table('users').update(sanitized_payload).eq('id', existing.get('id')).execute()
            return {'message': '既存ユーザーを更新しました', 'user_id': existing.get('id'), 'created': False}
        else:
            try:
                insert_res = supabase.table('users').insert(sanitized_payload).execute()
                new_id = None
                try:
                    new_id = insert_res.data[0].get('id')
                except Exception:
                    new_id = None
                return {'message': 'ユーザーを作成してカードを紐付けました', 'user_id': new_id, 'created': True}
            except Exception as ie:
                # Handle duplicate card_id unique constraint by updating the existing row
                msg = str(ie)
                if 'users_card_id_key' in msg or ('duplicate key' in msg and 'card_id' in msg):
                    try:
                        existing_by_card = supabase.table('users').select('*').eq('card_id', req.card_id).execute()
                        if existing_by_card.data:
                            uid = existing_by_card.data[0].get('id')
                            supabase.table('users').update(sanitized_payload).eq('id', uid).execute()
                            return {'message': '重複したカードIDの既存ユーザーを更新しました', 'user_id': uid, 'created': False}
                    except Exception:
                        # fall through to raise original
                        pass
                # re-raise to be handled by outer except
                raise ie
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to write user: {e}")

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
        # prefer stapro_staff_id saved in users; fallback to other fields
        raw_staff_id = user.get('stapro_staff_id') or user.get('staff_id') or user.get('id')
        staff_id_int = _safe_int(raw_staff_id)
        school_raw = user.get('stapro_school_id') or user.get('default_school_id') or 1
        school_id_int = _safe_int(school_raw) or 1
        commuting_costs = int(user.get('default_transport_cost', 0) or 0)

        if stapro_url and stapro_token and staff_id_int is not None:
            client = StaproAPIClient(base_url=stapro_url, api_token=stapro_token)
            work_day = date.today().isoformat()
            try:
                client.create_attendance(
                    staff_id=staff_id_int,
                    work_day=work_day,
                    school_id=int(school_id_int),
                    commuting_costs=commuting_costs,
                    another_time=0.0,
                    total_lesson=0,
                    lesson_ids=[],
                )
                external_created = True
            except Exception as e:
                print(f"Stapro create_attendance failed on clock-in: {e}")
        else:
            print(f"Skipping Stapro create_attendance on clock-in: invalid staff_id={raw_staff_id}")
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
        stapro_url = os.getenv("STAPRO_API_URL")
        stapro_token = os.getenv("STAPRO_API_TOKEN")

        raw_staff_id = user.get('stapro_staff_id') or user.get('staff_id') or user.get('id')
        staff_id_int = _safe_int(raw_staff_id)
        school_raw = user.get('stapro_school_id') or user.get('default_school_id') or 1
        school_id_int = _safe_int(school_raw) or 1

        if stapro_url and stapro_token and staff_id_int is not None:
            client = StaproAPIClient(base_url=stapro_url, api_token=stapro_token)
            work_day = date.today().isoformat()
            try:
                client.create_attendance(
                    staff_id=staff_id_int,
                    work_day=work_day,
                    school_id=int(school_id_int),
                    commuting_costs=int(req.transport_cost),
                    another_time=0.0,
                    total_lesson=int(req.class_count),
                    lesson_ids=(req.lesson_ids or []),
                )
                external_created = True
            except Exception as e:
                print(f"Stapro create_attendance failed on clock-out: {e}")
        else:
            print(f"Skipping Stapro create_attendance on clock-out: invalid staff_id={raw_staff_id}")
    except Exception as e:
        print(f"Stapro create_attendance failed on clock-out: {e}")

    return {"message": "退勤と業務報告が完了しました", "external_created": external_created}