from fastapi import FastAPI, HTTPException, Depends
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import List
import os
from dotenv import load_dotenv

from stapro_api_client import StaproAPIClient

# 環境変数を読み込み
load_dotenv()

app = FastAPI(
    title="スタートプログラミング API プロキシ",
    description="スタートプログラミング スタッフ管理システムのAPIを利用するサンプルアプリケーション",
    version="1.0.0",
)

# APIクライアントの設定
STAPRO_API_URL = os.getenv("STAPRO_API_URL", "http://localhost:3000")
STAPRO_API_TOKEN = os.getenv("STAPRO_API_TOKEN", "")


# ========================================
# リクエスト/レスポンスモデル
# ========================================


class LoginRequest(BaseModel):
    email: str
    password: str


class AttendanceCreate(BaseModel):
    staff_id: int
    work_day: str
    school_id: int
    commuting_costs: int
    another_time: float
    total_lesson: int
    lesson_ids: List[int]
    total_training_lesson: int = 0
    deduction_time: float = 0.0
    note: str = ""


# ========================================
# 依存性注入: APIクライアント
# ========================================


def get_api_client():
    """同期クライアントを返す依存関数（yield 形式）。"""
    client = StaproAPIClient(base_url=STAPRO_API_URL, api_token=STAPRO_API_TOKEN)
    try:
        yield client
    finally:
        # StaproAPIClient は内部で requests.Session を使うので、明示的に閉じる場合はここで行う
        try:
            client.session.close()
        except Exception:
            pass


# ========================================
# エンドポイント（同期実装）
# ========================================


@app.get("/")
def root():
    return {"message": "スタートプログラミング API プロキシ", "version": "1.0.0"}


@app.post("/auth/login")
def login(request: LoginRequest, client: StaproAPIClient = Depends(get_api_client)):
    try:
        user = client.authenticate(request.email, request.password)
        return user
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"認証失敗: {e}")


@app.get("/staffs/{staff_id}")
def get_staff(staff_id: int, client: StaproAPIClient = Depends(get_api_client)):
    try:
        return client.get_staff(staff_id)
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"スタッフが見つかりません: {e}")


@app.get("/schools")
def get_schools(client: StaproAPIClient = Depends(get_api_client)):
    try:
        return client.get_schools()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"教室一覧取得失敗: {e}")


@app.get("/schools/{school_id}")
def get_school(school_id: int, client: StaproAPIClient = Depends(get_api_client)):
    try:
        return client.get_school(school_id)
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"教室が見つかりません: {e}")


@app.get("/staffs/{staff_id}/attendances")
def get_attendances(staff_id: int, client: StaproAPIClient = Depends(get_api_client)):
    try:
        return client.get_attendances(staff_id)
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"勤怠情報が見つかりません: {e}")


@app.get("/attendances/{attendance_id}")
def get_attendance(attendance_id: int, client: StaproAPIClient = Depends(get_api_client)):
    try:
        return client.get_attendance(attendance_id)
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"勤怠情報が見つかりません: {e}")


@app.post("/attendances")
def create_attendance(request: AttendanceCreate, client: StaproAPIClient = Depends(get_api_client)):
    try:
        return client.create_attendance(
            staff_id=request.staff_id,
            work_day=request.work_day,
            school_id=request.school_id,
            commuting_costs=request.commuting_costs,
            another_time=request.another_time,
            total_lesson=request.total_lesson,
            lesson_ids=request.lesson_ids,
            total_training_lesson=request.total_training_lesson,
            deduction_time=request.deduction_time,
            note=request.note,
        )
    except Exception as e:
        raise HTTPException(status_code=422, detail=f"勤怠情報の登録失敗: {e}")


@app.delete("/attendances/{attendance_id}")
def delete_attendance(attendance_id: int, client: StaproAPIClient = Depends(get_api_client)):
    try:
        return client.delete_attendance(attendance_id)
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"勤怠情報の削除失敗: {e}")


# エラーハンドラー
@app.exception_handler(HTTPException)
def http_exception_handler(request, exc):
    return JSONResponse(status_code=exc.status_code, content={"error": exc.detail})


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)