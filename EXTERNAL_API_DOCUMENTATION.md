# API ドキュメント

## 概要

このドキュメントは、自社システムのREST APIの仕様を記載しています。

## 環境
- 本番: https://system.start-programming.net
- 開発/ステージング: https://staging.system.start-programming.net

## 認証

全てのAPIエンドポイントは固定のAPIトークンによる認証が必要です。

### 認証方法

リクエストヘッダーに以下を含める必要があります：

```
Authorization: Bearer <API_TOKEN>
```

### APIトークンの設定

`.env`ファイルに以下の環境変数を追加してください：

```
API_TOKEN=your_secure_api_token_here
```

| 環境 | APIトークン |
| --- | --- |
| 本番 | - |
| 開発/ステージング | `N29kIawUS49YWMRHDxBupOtuxmh0BUjKgfYi6uKrfmI=` |

## エンドポイント一覧

### 1. ユーザー認証

#### POST /api/v1/auth/login

メールアドレスとパスワードでユーザー情報を取得します。

**リクエスト:**

```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**レスポンス (200 OK):**

```json
{
  "id": 1,
  "email": "user@example.com",
  "last_name": "山田",
  "first_name": "太郎",
  "last_name_kana": "ヤマダ",
  "first_name_kana": "タロウ",
  "role_id": 1,
  "authority": 1,
  "status": 1,
  "commuting_costs": 500,
  "born_on": "1990-01-01",
  "entered_on": "2020-04-01",
  "retired_on": null
}
```

**エラーレスポンス:**

- 400 Bad Request: メールアドレスまたはパスワードが未入力
- 401 Unauthorized: 認証に失敗
- 404 Not Found: ユーザーが見つからない

---

### 2. ユーザー情報取得

#### GET /api/v1/staffs/:id

指定したIDのスタッフ情報を取得します。

**パラメータ:**

- `id` (必須): スタッフID

**レスポンス (200 OK):**

```json
{
  "id": 1,
  "email": "user@example.com",
  "last_name": "山田",
  "first_name": "太郎",
  "last_name_kana": "ヤマダ",
  "first_name_kana": "タロウ",
  "role_id": 1,
  "authority": 1,
  "status": 1,
  "commuting_costs": 500,
  "born_on": "1990-01-01",
  "entered_on": "2020-04-01",
  "retired_on": null
}
```

**エラーレスポンス:**

- 404 Not Found: スタッフが見つからない

---

### 3. 教室一覧取得

#### GET /api/v1/schools

開校中の教室一覧を取得します。

**レスポンス (200 OK):**

```json
{
  "schools": [
    {
      "id": 1,
      "name": "渋谷校",
      "kana": "シブヤコウ",
      "student": 25,
      "managed_lesson": 120,
      "is_opened": true,
      "opened_on": "2020-04-01",
      "closed_on": null,
      "created_at": "2020-03-01T10:00:00.000Z",
      "updated_at": "2024-01-15T10:00:00.000Z"
    },
    {
      "id": 2,
      "name": "新宿校",
      "kana": "シンジュクコウ",
      "student": 30,
      "managed_lesson": 150,
      "is_opened": true,
      "opened_on": "2020-05-01",
      "closed_on": null,
      "created_at": "2020-04-01T10:00:00.000Z",
      "updated_at": "2024-01-15T10:00:00.000Z"
    }
  ]
}
```

---

### 4. 教室詳細取得

#### GET /api/v1/schools/:id

指定したIDの教室情報を取得します。

**パラメータ:**

- `id` (必須): 教室ID

**レスポンス (200 OK):**

```json
{
  "id": 1,
  "name": "渋谷校",
  "kana": "シブヤコウ",
  "student": 25,
  "managed_lesson": 120,
  "is_opened": true,
  "opened_on": "2020-04-01",
  "closed_on": null,
  "created_at": "2020-03-01T10:00:00.000Z",
  "updated_at": "2024-01-15T10:00:00.000Z"
}
```

**エラーレスポンス:**

- 404 Not Found: 教室が見つからない

---

### 5. 勤怠情報一覧取得

#### GET /api/v1/staffs/:staff_id/attendances

指定したスタッフの勤怠情報一覧を取得します。

**パラメータ:**

- `staff_id` (必須): スタッフID

**レスポンス (200 OK):**

```json
{
  "staff_id": 1,
  "attendances": [
    {
      "id": 1,
      "staff_id": 1,
      "work_day": "2024-01-15",
      "school_id": 1,
      "school_name": "渋谷校",
      "commuting_costs": 500,
      "another_time": 0.5,
      "total_lesson": 4,
      "total_training_lesson": 1,
      "deduction_time": 0.0,
      "note": "特記事項なし",
      "lessons": [
        { "id": 1, "time": "16:00-17:00" },
        { "id": 2, "time": "17:00-18:00" }
      ],
      "created_at": "2024-01-15T10:00:00.000Z",
      "updated_at": "2024-01-15T10:00:00.000Z"
    }
  ]
}
```

**エラーレスポンス:**

- 404 Not Found: スタッフが見つからない

---

### 4. 勤怠情報詳細取得

#### GET /api/v1/attendances/:id

指定したIDの勤怠情報を取得します。

**パラメータ:**

- `id` (必須): 勤怠情報ID

**レスポンス (200 OK):**

```json
{
  "id": 1,
  "staff_id": 1,
  "work_day": "2024-01-15",
  "school_id": 1,
  "school_name": "渋谷校",
  "commuting_costs": 500,
  "another_time": 0.5,
  "total_lesson": 4,
  "total_training_lesson": 1,
  "deduction_time": 0.0,
  "note": "特記事項なし",
  "lessons": [
    { "id": 1, "time": "16:00-17:00" },
    { "id": 2, "time": "17:00-18:00" }
  ],
  "created_at": "2024-01-15T10:00:00.000Z",
  "updated_at": "2024-01-15T10:00:00.000Z"
}
```

**エラーレスポンス:**

- 404 Not Found: 勤怠情報が見つからない

---

### 5. 勤怠情報登録

#### POST /api/v1/attendances

新しい勤怠情報を登録します。

**リクエスト:**

```json
{
  "attendance": {
    "staff_id": 1,
    "work_day": "2024-01-15",
    "school_id": 1,
    "commuting_costs": 500,
    "another_time": 0.5,
    "total_lesson": 4,
    "total_training_lesson": 1,
    "deduction_time": 0.0,
    "note": "特記事項なし"
  },
  "lesson_ids": [1, 2, 3, 4],
  "total_training_lesson": 1
}
```

**パラメータ説明:**

- `staff_id` (必須): スタッフID
- `work_day` (必須): 勤務日
- `school_id` (必須): 教室ID
- `commuting_costs` (必須): 交通費
- `another_time` (必須): その他の時間
- `total_lesson` (必須): 総授業数
- `total_training_lesson`: 研修授業数（デフォルト: 0）
- `deduction_time`: 控除時間（デフォルト: 0.0）
- `note`: 備考
- `lesson_ids`: レッスンIDの配列

**レスポンス (201 Created):**

```json
{
  "message": "勤怠情報を登録しました",
  "attendance": {
    "id": 1,
    "staff_id": 1,
    "work_day": "2024-01-15",
    "school_id": 1,
    "school_name": "渋谷校",
    "commuting_costs": 500,
    "another_time": 0.5,
    "total_lesson": 4,
    "total_training_lesson": 1,
    "deduction_time": 0.0,
    "note": "特記事項なし",
    "lessons": [
      { "id": 1, "time": "16:00-17:00" },
      { "id": 2, "time": "17:00-18:00" }
    ],
    "created_at": "2024-01-15T10:00:00.000Z",
    "updated_at": "2024-01-15T10:00:00.000Z"
  }
}
```

**エラーレスポンス:**

- 422 Unprocessable Entity: バリデーションエラー

```json
{
  "error": "Validation Error",
  "message": "勤怠情報の登録に失敗しました",
  "errors": [
    "Staff を入力してください",
    "Work day を入力してください"
  ]
}
```

---

### 6. 勤怠情報削除

#### DELETE /api/v1/attendances/:id

指定したIDの勤怠情報を削除します。

**パラメータ:**

- `id` (必須): 勤怠情報ID

**レスポンス (200 OK):**

```json
{
  "message": "勤怠情報を削除しました"
}
```

**エラーレスポンス:**

- 404 Not Found: 勤怠情報が見つからない
- 422 Unprocessable Entity: 削除に失敗

---

## エラーレスポンスの形式

全てのエラーレスポンスは以下の形式で返されます：

```json
{
  "error": "エラータイプ",
  "message": "エラーメッセージ"
}
```

### HTTPステータスコード

- `200 OK`: リクエスト成功
- `201 Created`: リソース作成成功
- `400 Bad Request`: リクエストが不正
- `401 Unauthorized`: 認証失敗
- `404 Not Found`: リソースが見つからない
- `422 Unprocessable Entity`: バリデーションエラー

---

## リクエスト例

### cURL

```bash
# ユーザー認証
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Authorization: Bearer your_api_token" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'

# スタッフ情報取得
curl -X GET http://localhost:3000/api/v1/staffs/1 \
  -H "Authorization: Bearer your_api_token"

# 教室一覧取得
curl -X GET http://localhost:3000/api/v1/schools \
  -H "Authorization: Bearer your_api_token"

# 教室詳細取得
curl -X GET http://localhost:3000/api/v1/schools/1 \
  -H "Authorization: Bearer your_api_token"

# 勤怠情報一覧取得
curl -X GET http://localhost:3000/api/v1/staffs/1/attendances \
  -H "Authorization: Bearer your_api_token"

# 勤怠情報登録
curl -X POST http://localhost:3000/api/v1/attendances \
  -H "Authorization: Bearer your_api_token" \
  -H "Content-Type: application/json" \
  -d '{
    "attendance": {
      "staff_id": 1,
      "work_day": "2024-01-15",
      "school_id": 1,
      "commuting_costs": 500,
      "another_time": 0.5,
      "total_lesson": 4,
      "total_training_lesson": 1,
      "deduction_time": 0.0,
      "note": ""
    },
    "lesson_ids": [1, 2, 3, 4],
    "total_training_lesson": 1
  }'

# 勤怠情報削除
curl -X DELETE http://localhost:3000/api/v1/attendances/1 \
  -H "Authorization: Bearer your_api_token"
```

---

## セキュリティに関する注意事項

1. APIトークンは絶対に公開しないでください
2. HTTPS通信を使用することを強く推奨します
3. APIトークンは定期的に変更することを推奨します
4. 本番環境では、適切なレート制限を実装することを推奨します

---

## 設定手順

### 1. 環境変数の設定

`.env`ファイルに以下を追加：

```
API_TOKEN=your_secure_random_token_here
```

セキュアなトークンを生成する例：

```bash
# Rubyを使用
ruby -rsecurerandom -e 'puts SecureRandom.urlsafe_base64(32)'

# OpenSSLを使用
openssl rand -base64 32
```

### 2. サーバーの再起動

環境変数の変更後は、サーバーを再起動してください。

```bash
# Dockerを使用している場合
docker-compose restart web

# 直接起動している場合
rails restart
```

### 3. 動作確認

以下のコマンドで動作確認ができます：

```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Authorization: Bearer your_api_token" \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password"}'
```