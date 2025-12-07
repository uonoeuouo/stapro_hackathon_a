"""
スタートプログラミング スタッフ管理システム API クライアント（同期版）

使用方法:
    from stapro_api_client import StaproAPIClient

    client = StaproAPIClient(
        base_url="http://localhost:3000",
        api_token="your_api_token_here"
    )

    # ユーザー認証
    user = client.authenticate("user@example.com", "password123")
    print(user)
"""

import requests
import logging
from typing import Optional, Dict, List, Any
from datetime import date


class StaproAPIClient:
    """スタートプログラミング スタッフ管理システム API クライアント"""

    def __init__(self, base_url: str, api_token: str):
        """
        Args:
            base_url: APIのベースURL（例: http://localhost:3000）
            api_token: APIトークン
        """
        self.base_url = base_url.rstrip('/')
        self.api_token = api_token
        self.session = requests.Session()
        self.session.headers.update({
            'Authorization': f'Bearer {api_token}',
            'Content-Type': 'application/json'
        })

    def _get(self, endpoint: str) -> Dict[str, Any]:
        """GETリクエストを送信"""
        response = self.session.get(f"{self.base_url}{endpoint}")
        response.raise_for_status()
        return response.json()

    def _post(self, endpoint: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """POSTリクエストを送信"""
        response = self.session.post(f"{self.base_url}{endpoint}", json=data)
        try:
            response.raise_for_status()
        except requests.exceptions.HTTPError as e:
            # Log payload and response body to help diagnose 4xx/5xx errors
            try:
                logging.error("Stapro API POST %s returned %s", endpoint, response.status_code)
                logging.error("Request payload: %s", data)
                logging.error("Response body: %s", response.text)
            except Exception:
                pass
            raise
        return response.json()

    def _delete(self, endpoint: str) -> Dict[str, Any]:
        """DELETEリクエストを送信"""
        response = self.session.delete(f"{self.base_url}{endpoint}")
        response.raise_for_status()
        return response.json()

    # ========================================
    # 認証API
    # ========================================

    def authenticate(self, email: str, password: str) -> Dict[str, Any]:
        """
        ユーザー認証（ID, PWでユーザー情報を取得）

        Args:
            email: メールアドレス
            password: パスワード

        Returns:
            ユーザー情報

        Example:
            >>> client.authenticate("user@example.com", "password123")
            {
                'id': 1,
                'email': 'user@example.com',
                'last_name': '山田',
                'first_name': '太郎',
                ...
            }
        """
        # Try common login endpoints. Some deployments expose `/auth/login` (proxy),
        # others use `/api/v1/auth/login` (direct API). Try both and return the first success.
        payload = {'email': email, 'password': password}
        last_exc = None
        for endpoint in ['/api/v1/auth/login', '/auth/login']:
            try:
                return self._post(endpoint, payload)
            except requests.exceptions.HTTPError as e:
                # keep the last exception to raise if all attempts fail
                last_exc = e
                # try next endpoint
                continue
        # If we reach here, both endpoints failed — raise the last HTTPError
        if last_exc:
            raise last_exc
        # Fallback: raise a generic error (shouldn't normally happen)
        raise Exception('Authentication failed for unknown reasons')

    # ========================================
    # スタッフAPI
    # ========================================

    def get_staff(self, staff_id: int) -> Dict[str, Any]:
        """
        スタッフ情報取得（ID指定）

        Args:
            staff_id: スタッフID

        Returns:
            スタッフ情報

        Example:
            >>> client.get_staff(1)
            {
                'id': 1,
                'email': 'user@example.com',
                'last_name': '山田',
                ...
            }
        """
        return self._get(f'/api/v1/staffs/{staff_id}')

    # ========================================
    # 教室API
    # ========================================

    def get_schools(self) -> List[Dict[str, Any]]:
        """
        教室一覧取得

        Returns:
            教室一覧

        Example:
            >>> schools = client.get_schools()
            >>> for school in schools['schools']:
            ...     print(school['name'])
        """
        return self._get('/api/v1/schools')

    def get_school(self, school_id: int) -> Dict[str, Any]:
        """
        教室詳細取得

        Args:
            school_id: 教室ID

        Returns:
            教室情報

        Example:
            >>> school = client.get_school(1)
            >>> print(school['name'])
            >>> print(school['timetables'])
        """
        return self._get(f'/api/v1/schools/{school_id}')

    # ========================================
    # 勤怠情報API
    # ========================================

    def get_attendances(self, staff_id: int) -> Dict[str, Any]:
        """
        勤怠情報一覧取得（スタッフID指定）

        Args:
            staff_id: スタッフID

        Returns:
            勤怠情報一覧

        Example:
            >>> attendances = client.get_attendances(1)
            >>> for attendance in attendances['attendances']:
            ...     print(attendance['work_day'])
        """
        return self._get(f'/api/v1/staffs/{staff_id}/attendances')

    def get_attendance(self, attendance_id: int) -> Dict[str, Any]:
        """
        勤怠情報詳細取得（ID指定）

        Args:
            attendance_id: 勤怠情報ID

        Returns:
            勤怠情報

        Example:
            >>> attendance = client.get_attendance(1)
            >>> print(attendance['work_day'])
        """
        return self._get(f'/api/v1/attendances/{attendance_id}')

    def create_attendance(
        self,
        staff_id: int,
        work_day: str,
        school_id: int,
        commuting_costs: int,
        another_time: float,
        total_lesson: int,
        lesson_ids: List[int],
        total_training_lesson: int = 0,
        deduction_time: float = 0.0,
        note: str = ""
    ) -> Dict[str, Any]:
        """
        勤怠情報登録

        Args:
            staff_id: スタッフID
            work_day: 勤務日（YYYY-MM-DD形式）
            school_id: 教室ID
            commuting_costs: 交通費
            another_time: その他の時間
            total_lesson: 総授業数
            lesson_ids: レッスンIDの配列
            total_training_lesson: 研修授業数（デフォルト: 0）
            deduction_time: 控除時間（デフォルト: 0.0）
            note: 備考

        Returns:
            登録した勤怠情報

        Example:
            >>> attendance = client.create_attendance(
            ...     staff_id=1,
            ...     work_day="2024-01-15",
            ...     school_id=1,
            ...     commuting_costs=500,
            ...     another_time=0.5,
            ...     total_lesson=4,
            ...     lesson_ids=[1, 2, 3, 4]
            ... )
        """
        # API が期待するフラットなリクエストボディ形式に合わせる
        payload = {
            'staff_id': staff_id,
            'work_day': work_day,
            'school_id': school_id,
            'commuting_costs': commuting_costs,
            'another_time': another_time,
            'total_lesson': total_lesson,
            'lesson_ids': lesson_ids,
            'total_training_lesson': total_training_lesson,
            'deduction_time': deduction_time,
            'note': note,
        }
        return self._post('/api/v1/attendances', payload)

    def delete_attendance(self, attendance_id: int) -> Dict[str, Any]:
        """
        勤怠情報削除

        Args:
            attendance_id: 勤怠情報ID

        Returns:
            削除結果

        Example:
            >>> result = client.delete_attendance(1)
            >>> print(result['message'])
        """
        return self._delete(f'/api/v1/attendances/{attendance_id}')


if __name__ == '__main__':
    # 使用例
    client = StaproAPIClient(
        base_url="http://localhost:3000",
        api_token="your_api_token_here"
    )

    # ユーザー認証
    try:
        user = client.authenticate("user@example.com", "password123")
        print("認証成功:", user)
    except requests.exceptions.HTTPError as e:
        print("認証失敗:", e)

    # 教室一覧取得
    try:
        schools = client.get_schools()
        print("\n教室一覧:")
        for school in schools['schools']:
            print(f"- {school['name']} (ID: {school['id']})")
            if school['timetables']:
                print(f"  タイムテーブル: {len(school['timetables'])}件")
    except requests.exceptions.HTTPError as e:
        print("教室一覧取得失敗:", e)

    # スタッフ情報取得
    try:
        staff = client.get_staff(1)
        print(f"\nスタッフ情報: {staff['last_name']} {staff['first_name']}")
    except requests.exceptions.HTTPError as e:
        print("スタッフ情報取得失敗:", e)