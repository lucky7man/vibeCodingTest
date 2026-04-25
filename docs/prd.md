# PRD — Todo MVP (Minimal Vibecoding Product)

> **버전**: 1.0  
> **작성일**: 2026-04-23  
> **상태**: 승인 완료 — Sprint 1 착수 가능  
> **사전 결정 문서**: [prod-prd.md](./prod-prd.md)

---

## 1. 제품 개요

### 한 줄 정의
로그인한 사용자가 자신의 할 일을 우선순위·마감일·카테고리·리스트로 관리할 수 있는 데스크탑 웹 기반 Todo 앱.

### 배경
바이브 코딩(AI 보조 개발) 학습 라이브 데모를 위한 프로젝트.  
**잘 만든 Todo 앱 자체가 목표가 아니라, AI와 함께 빠르게 풀스택 앱을 만들어내는 과정 시연**이 목표다.

### 타겟 사용자
- 바이브 코딩 학습 데모 청중 (개발 입문자, 현직 개발자, 비개발자 포함)
- 데모 시연 시 직접 앱을 사용해보는 모든 사람

### 비목표 (Non-goals)
- 클라우드 배포 (로컬 데모로 종료)
- 모바일 대응 (데스크탑 전용)
- 팀 협업 / 공유 기능
- 알림 / 이메일 / 푸시
- 프로덕션급 운영 (관찰성, 스케일링, 백업)

---

## 2. 사용자 스토리 (P0)

| ID | 스토리 |
|----|-------|
| US-1 | 사용자로서, **아이디와 비밀번호로 회원가입**하여 내 전용 공간을 갖고 싶다. |
| US-2 | 사용자로서, **로그인**하여 이전에 만든 Todo를 다시 볼 수 있어야 한다. |
| US-3 | 사용자로서, **새 Todo를 빠르게 입력**해서 머릿속의 할 일을 즉시 기록하고 싶다. |
| US-4 | 사용자로서, **완료한 Todo를 체크**해서 진행 상황을 표시하고 싶다. |
| US-5 | 사용자로서, **Todo의 제목/설명/우선순위/마감일/카테고리를 수정**할 수 있어야 한다. |
| US-6 | 사용자로서, **불필요한 Todo를 삭제**할 수 있어야 한다. |
| US-7 | 사용자로서, **우선순위(높음/중간/낮음)** 를 부여해 중요한 일을 구분하고 싶다. |
| US-8 | 사용자로서, **마감일을 지정**해 언제까지 해야 할 일인지 표시하고 싶다. |
| US-9 | 사용자로서, **카테고리(태그)** 로 Todo를 분류하고 싶다. |
| US-10 | 사용자로서, **여러 개의 Todo 리스트**를 만들어 영역별로 할 일을 분리하고 싶다. |
| US-11 | 사용자로서, **키워드로 Todo를 검색**하고 **상태/우선순위로 필터링**해서 원하는 항목만 보고 싶다. |
| US-12 | 사용자로서, **생성일/마감일/우선순위 기준으로 정렬**해 보고 싶다. |

---

## 3. 기능 요구사항

### P0 — MVP 필수 (2주 내 완성)
- 회원가입 / 로그인 (username + password, 이메일 인증 없음)
- JWT 기반 인증 (만료 24시간, `Authorization: Bearer <token>`)
- 사용자별 데이터 격리 (서버에서 user_id 검증 필수)
- Todo CRUD (생성·조회·수정·삭제)
- 완료 체크 토글
- 우선순위 (high / medium / low)
- 마감일 (날짜만, 시간/알림 없음)
- 카테고리 / 태그 (사용자별 직접 정의, 색상 지정)
- Todo 그룹 (리스트) — 사용자별 N개
- 검색 (제목 키워드)
- 필터 (완료 상태, 우선순위, 리스트, 카테고리)
- 정렬 (생성일 / 마감일 / 우선순위)

### P1 — MVP 이후 (이번 범위 아님)
- 드래그 앤 드롭 순서 변경
- 팀 공유 / 협업
- 알림 (브라우저 푸시 / 이메일)
- 반복 일정 Todo
- 파일 첨부
- 소셜 로그인 (Google / GitHub OAuth)
- 비밀번호 찾기 / 변경

---

## 4. 비기능 요구사항

| 영역 | 요구사항 |
|------|---------|
| **성능** | 모든 API 응답 < 500ms (단일 사용자, 로컬 SQLite 기준) |
| **보안** | 비밀번호는 `bcryptjs`로 해시 저장. JWT 만료 24h. 모든 인증 필요 엔드포인트는 토큰의 user_id로 리소스 소유권 검증 |
| **코드 품질** | TypeScript strict 모드. ESLint + Prettier 통과. `pnpm build` 무에러 |
| **테스트** | 커버리지 목표 없음. Playwright E2E 시나리오 최소 1개(로그인→Todo 생성→완료→삭제) 통과 |
| **관찰성** | API Route Handler에서 요청/에러를 콘솔 + 파일(`logs/app.log`)로 기록 |
| **가용성** | `pnpm dev` 한 줄로 전체 앱 기동 (Docker는 선택) |

---

## 5. 기술 스택

> 풀스택 TypeScript 단일 앱 — 한 언어, 타입 공유, 빠른 시연에 최적화

### 스택 요약

| 영역 | 선택 | 비고 |
|------|------|------|
| 프레임워크 | **Next.js 15 (App Router)** + TypeScript | API + UI + 라우팅을 한 앱에서 처리 |
| 백엔드 | Next.js Route Handlers (`app/api/.../route.ts`) | 별도 서버 프로세스 없음 |
| DB | SQLite (단일 파일) | `data/app.db` |
| ORM | **Drizzle ORM** | 타입 안전 스키마, 마이그레이션 내장 |
| 인증 | JWT (`jose`) + `bcryptjs` | 24h 만료, `Authorization: Bearer` |
| 검증 | **Zod** | 요청/폼 공통 스키마 |
| 스타일 | Tailwind CSS | |
| UI 컴포넌트 | **shadcn/ui** | 다크모드 기본 지원 |
| 클라이언트 상태 | **TanStack Query** | 캐싱·낙관적 업데이트 |
| 폼 | react-hook-form + Zod 리졸버 | |
| 패키지 매니저 | pnpm | |
| E2E | Playwright | |
| 컨테이너 | Docker Compose (선택) | `pnpm dev`로도 충분 |

### 프로젝트 폴더 구조

```
/
├── src/
│   ├── app/
│   │   ├── api/
│   │   │   ├── auth/{register,login,me}/route.ts
│   │   │   ├── lists/route.ts            # GET, POST
│   │   │   ├── lists/[id]/route.ts       # PATCH, DELETE
│   │   │   ├── categories/route.ts
│   │   │   ├── categories/[id]/route.ts
│   │   │   ├── todos/route.ts            # GET (필터/정렬), POST
│   │   │   └── todos/[id]/route.ts       # PATCH, DELETE
│   │   ├── login/page.tsx
│   │   ├── register/page.tsx
│   │   ├── layout.tsx                    # 루트 레이아웃 (다크모드 적용)
│   │   ├── page.tsx                      # 메인 (보호 라우트)
│   │   └── providers.tsx                 # TanStack Query Provider
│   ├── components/
│   │   ├── ui/                           # shadcn/ui 컴포넌트
│   │   ├── Sidebar.tsx
│   │   ├── TodoList.tsx
│   │   ├── TodoItem.tsx
│   │   ├── NewTodoInput.tsx
│   │   ├── TodoEditDialog.tsx
│   │   ├── SearchFilterBar.tsx
│   │   └── ThemeToggle.tsx
│   ├── lib/
│   │   ├── auth.ts                       # JWT 발급/검증, 미들웨어 헬퍼
│   │   ├── api-client.ts                 # fetch 래퍼 (Authorization 자동 주입)
│   │   └── validators.ts                 # Zod 스키마 모음
│   └── db/
│       ├── schema.ts                     # Drizzle 스키마
│       ├── client.ts                     # DB 연결
│       └── migrations/                   # drizzle-kit 출력
├── data/                                 # SQLite 파일 (gitignore)
├── tests/e2e/                            # Playwright
├── drizzle.config.ts
├── next.config.ts
├── tailwind.config.ts
├── package.json
├── .env.local.example
├── docker-compose.yml                    # 선택 사항
└── docs/
    ├── prod-prd.md
    └── prd.md
```

---

## 6. 데이터 모델

### ER 관계
- `users` 1 : N `todo_lists`
- `users` 1 : N `categories`
- `users` 1 : N `todos`
- `todos` N : 1 `todo_lists` (nullable — 미분류 Todo 허용)
- `todos` N : 1 `categories` (nullable)

### Drizzle 스키마 (`src/db/schema.ts`)

```ts
import { sqliteTable, integer, text, index } from 'drizzle-orm/sqlite-core';
import { sql } from 'drizzle-orm';

export const users = sqliteTable('users', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  username: text('username').notNull().unique(),
  password: text('password').notNull(),                    // bcrypt hash
  createdAt: text('created_at').default(sql`CURRENT_TIMESTAMP`),
});

export const todoLists = sqliteTable('todo_lists', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  userId: integer('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  name: text('name').notNull(),
  createdAt: text('created_at').default(sql`CURRENT_TIMESTAMP`),
});

export const categories = sqliteTable('categories', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  userId: integer('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  name: text('name').notNull(),
  color: text('color'),                                    // #RRGGBB
});

export const todos = sqliteTable(
  'todos',
  {
    id: integer('id').primaryKey({ autoIncrement: true }),
    userId: integer('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
    listId: integer('list_id').references(() => todoLists.id, { onDelete: 'set null' }),
    categoryId: integer('category_id').references(() => categories.id, { onDelete: 'set null' }),
    title: text('title').notNull(),
    description: text('description'),
    isCompleted: integer('is_completed', { mode: 'boolean' }).notNull().default(false),
    priority: text('priority', { enum: ['high', 'medium', 'low'] }).notNull().default('medium'),
    dueDate: text('due_date'),                             // YYYY-MM-DD
    createdAt: text('created_at').default(sql`CURRENT_TIMESTAMP`),
    updatedAt: text('updated_at').default(sql`CURRENT_TIMESTAMP`),
  },
  (t) => ({
    byUser: index('idx_todos_user_id').on(t.userId),
    byDue: index('idx_todos_due_date').on(t.dueDate),
    byCompleted: index('idx_todos_is_completed').on(t.isCompleted),
  }),
);
```

마이그레이션은 `drizzle-kit generate` → `drizzle-kit migrate` 흐름으로 관리.

---

## 7. API 설계 (REST)

### 공통 규약
- **Base URL**: `/api` (Next.js Route Handlers — `src/app/api/.../route.ts`)
- **인증 헤더**: `Authorization: Bearer <JWT>`
- **요청/응답 검증**: Zod 스키마로 양방향 검증 (`src/lib/validators.ts` 공통 모듈)
- **응답 포맷**:
  - 성공: `{ "data": ... }`
  - 실패: `{ "error": { "code": "STRING_CODE", "message": "사용자 친화 메시지" } }`
- **상태 코드**: `200 OK` / `201 Created` / `400 Bad Request` / `401 Unauthorized` / `403 Forbidden` / `404 Not Found` / `500 Internal Server Error`

### 엔드포인트 목록

| # | 메서드 | 경로 | 설명 | 인증 |
|---|-------|------|------|:----:|
| 1 | POST | `/api/auth/register` | 회원가입 (`username`, `password`) | ❌ |
| 2 | POST | `/api/auth/login` | 로그인 → JWT 반환 | ❌ |
| 3 | GET  | `/api/auth/me` | 현재 사용자 정보 | ✅ |
| 4 | GET  | `/api/lists` | 내 Todo 리스트 목록 | ✅ |
| 5 | POST | `/api/lists` | 리스트 생성 | ✅ |
| 6 | PATCH | `/api/lists/:id` | 리스트 수정 | ✅ |
| 7 | DELETE | `/api/lists/:id` | 리스트 삭제 | ✅ |
| 8 | GET  | `/api/categories` | 내 카테고리 목록 | ✅ |
| 9 | POST | `/api/categories` | 카테고리 생성 | ✅ |
| 10 | PATCH | `/api/categories/:id` | 카테고리 수정 | ✅ |
| 11 | DELETE | `/api/categories/:id` | 카테고리 삭제 | ✅ |
| 12 | GET  | `/api/todos` | Todo 목록 조회 | ✅ |
| 13 | POST | `/api/todos` | Todo 생성 | ✅ |
| 14 | PATCH | `/api/todos/:id` | Todo 수정 (완료 토글 포함) | ✅ |
| 15 | DELETE | `/api/todos/:id` | Todo 삭제 | ✅ |

### `GET /api/todos` 쿼리 파라미터

| 파라미터 | 타입 | 설명 |
|---------|------|-----|
| `q` | string | 제목 키워드 검색 |
| `list_id` | int | 특정 리스트 필터 |
| `category_id` | int | 특정 카테고리 필터 |
| `priority` | enum | `high` / `medium` / `low` |
| `is_completed` | bool | `true` / `false` |
| `sort` | enum | `created_at` / `due_date` / `priority` (기본: `created_at` 내림차순) |

---

## 8. UI 플로우

### 라우트 (Next.js App Router)

| 경로 | 파일 | 화면 | 보호 |
|------|------|------|:----:|
| `/login` | `app/login/page.tsx` | 로그인 폼 | ❌ |
| `/register` | `app/register/page.tsx` | 회원가입 폼 | ❌ |
| `/` | `app/page.tsx` | 메인 (사이드바 + Todo 목록) | ✅ |

보호 라우트는 클라이언트 컴포넌트에서 `localStorage.token` 부재 시 `/login`으로 `router.replace` 호출.

### 메인 화면 레이아웃 (Todoist 스타일)

```
┌──────────────────────────┬─────────────────────────────────────┐
│  사용자명 (username)     │  [🔍 검색바]   [필터] [정렬]        │
│  ──────────────────────  │  ─────────────────────────────────  │
│  📋 리스트               │  ☐ Todo 제목         🔴 4/30        │
│    • 업무                │  ☑ 완료된 항목       🟡 4/24        │
│    • 개인                │  ☐ 다른 항목         🟢 -           │
│    + 새 리스트           │  ...                                │
│  ──────────────────────  │  ─────────────────────────────────  │
│  🏷  카테고리            │  [+ 새 Todo 입력 ...]               │
│    • 긴급 (red)          │                                     │
│    • 학습 (blue)         │                                     │
│    + 새 카테고리         │                                     │
│  ──────────────────────  │                                     │
│  🌓 다크모드  [로그아웃] │                                     │
└──────────────────────────┴─────────────────────────────────────┘
```

### 인증 플로우
1. 비로그인 사용자가 `/` 접근 → `/login`으로 리다이렉트
2. 로그인 성공 → JWT를 `localStorage.token`에 저장 → `/`로 이동
3. 모든 API 요청에 `Authorization: Bearer <token>` 헤더 자동 주입 (`src/lib/api-client.ts` fetch 래퍼)
4. API에서 `401` 응답 수신 → `localStorage` 비우고 `/login` 리다이렉트

### Todo 조작 플로우
- **신규 생성**: 하단 입력창에 제목 입력 → Enter → 낙관적 업데이트 → 서버 응답으로 확정 (실패 시 롤백)
- **완료 토글**: 체크박스 클릭 → `PATCH /api/todos/:id` → TanStack Query 캐시 무효화
- **수정**: Todo 행 클릭 → `TodoEditDialog`에서 제목·설명·우선순위·마감일·카테고리 편집
- **삭제**: Todo 행 우측 메뉴(⋯) → 삭제 → 확인 다이얼로그 → `DELETE`

### 다크모드
- shadcn/ui `Dialog`/`Button` 등 컴포넌트는 다크모드 기본 지원
- `ThemeToggle` 컴포넌트를 사이드바 하단에 배치
- 사용자 선택은 `localStorage.theme`에 영속화 (`light` / `dark`)

---

## 9. 마일스톤

### Sprint 1 — 백엔드(API) + 데이터 (1주차)

**산출물**
- Next.js 15 + TypeScript 프로젝트 초기화 (`pnpm create next-app`)
- Tailwind CSS + shadcn/ui 초기 셋업
- Drizzle ORM 스키마 (`src/db/schema.ts`) + 마이그레이션 (4개 테이블, 인덱스 3개)
- 인증 모듈 (`src/lib/auth.ts`): JWT 발급/검증, bcrypt 해시
- API Route Handlers 15개 (`/api/auth/*`, `/api/lists/*`, `/api/categories/*`, `/api/todos/*`)
- Zod 검증 스키마 (`src/lib/validators.ts`)
- user_id 격리 검증 (모든 인증 엔드포인트)
- `.env.local.example`, `drizzle.config.ts`

**Definition of Done**
- `pnpm dev` 한 줄로 앱 기동
- `curl`로 회원가입 → 로그인 → JWT 획득 → Todo 생성/조회/완료 토글/삭제 전 흐름 수동 검증
- `pnpm typecheck && pnpm lint` 무에러 통과

### Sprint 2 — UI + 통합 (2주차)

**산출물**
- App Router 페이지 3개 (`/login`, `/register`, `/`)
- TanStack Query Provider + 인증 헤더 자동 주입 fetch 래퍼 (`src/lib/api-client.ts`)
- 메인 화면 컴포넌트 (Sidebar / SearchFilterBar / TodoList / TodoItem / NewTodoInput / TodoEditDialog / ThemeToggle)
- 다크모드 토글 + `localStorage.theme` 영속화
- 낙관적 업데이트 (Todo 생성·완료 토글)
- Playwright 시나리오 1개: 회원가입 → 로그인 → Todo 생성 → 완료 → 삭제
- (선택) `docker-compose.yml` 작성

**Definition of Done**
- 브라우저에서 회원가입 → 로그인 → Todo 생성/완료/삭제 전 흐름 동작
- Playwright 테스트 1개 통과
- 새로고침 후에도 데이터 유지 확인 (성공 기준)
