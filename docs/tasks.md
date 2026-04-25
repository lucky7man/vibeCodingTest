# Todo MVP 구현 계획 (Implementation Plan)

## Context

**왜 이 계획이 필요한가**
- [docs/prd.md](./prd.md)는 "무엇을 만들지"는 모두 정해놨지만, "어떻게 만들지(공통 패턴, 파일 간 의존, 함정)"는 비어 있다.
- 라이브 데모 특성상 **첫 파일을 만들기 전에 공통 패턴(응답 엔벨로프, 소유권 검증, 에러 코드 등)을 못 박아두지 않으면 매 핸들러마다 다르게 구현되어 청중이 혼란스러워진다.**
- 이 문서는 두 부분으로 구성된다:
  1. **구현 전략** — 모든 파일에 일관되게 적용할 패턴/결정
  2. **실행 체크리스트** — 단계별 task 표 (한 번에 하나씩 처리)

**현재 상태 (2026-04-25 기준)**
- 코드: 없음. 프로젝트는 GitHub에 push만 된 상태 (`docs/`, `.claude/`, `.gitignore`, `CLAUDE.md`만 존재).
- 리모트: https://github.com/lucky7man/vibeCodingTest (`main` 브랜치).
- 다음 단일 명령: `pnpm create next-app@latest .` (단계 0의 시작점).

---

## 구현 전략 (Implementation Strategy)

### 1. 레이어 아키텍처

```
[ 클라이언트 컴포넌트 ]
        │  TanStack Query
        ▼
[ src/lib/api-client.ts ]   ← fetch 래퍼 (JWT 자동 주입, 401 → /login)
        │  HTTP
        ▼
[ src/app/api/.../route.ts ] ← 검증·인증·소유권 체크·응답 포맷
        │  함수 호출
        ▼
[ src/db/client.ts ]        ← Drizzle 인스턴스 (싱글턴)
        │  SQL
        ▼
[ data/app.db ]             ← SQLite 파일
```

**규칙**: 서비스 레이어 없음. Route Handler가 Drizzle을 직접 호출. 데모용 단순함이 우선.

### 2. 공통 패턴 (모든 핸들러가 따른다)

**A. 응답 엔벨로프** — `src/lib/response.ts`
```ts
ok(data, status = 200)               → NextResponse.json({ data }, { status })
fail(code, message, status)          → NextResponse.json({ error: { code, message } }, { status })
```
에러 코드 표준 (모든 핸들러 공통):
| code | HTTP | 의미 |
|------|------|------|
| `VALIDATION_FAILED` | 400 | Zod 검증 실패 (`message`에 첫 번째 이슈) |
| `UNAUTHENTICATED` | 401 | 토큰 부재/만료 |
| `NOT_FOUND` | 404 | 리소스 없음 또는 **다른 사용자 소유** (의도적으로 구분 안 함) |
| `CONFLICT` | 409 | username 중복 등 |
| `INTERNAL` | 500 | 그 외 |

**B. 소유권 검증** — 모든 인증 핸들러의 정형 패턴
```ts
const auth = await requireAuth(req);
if (!auth.ok) return auth.response;          // 401
const { userId } = auth;

const row = await db.query.todos.findFirst({
  where: and(eq(todos.id, id), eq(todos.userId, userId)),  // ← userId 필터 필수
});
if (!row) return fail('NOT_FOUND', 'Todo를 찾을 수 없습니다', 404);
```
> **403이 아니라 404**: 다른 사용자의 리소스 ID인지 알려주지 않기 위함.

**C. JWT 페이로드 모양** (jose, HS256, 24h)
```ts
{ sub: string(userId), iat, exp }            // 페이로드는 sub만
```

**D. Zod 스키마는 단일 소스** — `src/lib/validators.ts`
- 같은 스키마를 (1) Route Handler 입력 검증, (2) react-hook-form `zodResolver`에서 동시에 사용.
- 타입은 `z.infer<typeof schema>`로 export.

**E. TanStack Query 키 컨벤션** — `src/lib/api-client.ts`
```ts
['auth', 'me']
['lists']
['categories']
['todos', { q, listId, categoryId, priority, isCompleted, sort }]
```
변이 후 무효화: 리스트/카테고리 변이 → `['lists']` or `['categories']` + `['todos']` (외래키 영향).

### 3. 런타임/플랫폼 주의사항

- **`runtime = 'nodejs'` 필수**: `better-sqlite3`(네이티브), `bcryptjs`, `jose`(`HS256`은 OK이나 일관성 위해 nodejs)는 모두 Node 런타임에서 동작. **모든 `route.ts` 상단에 `export const runtime = 'nodejs';`** 명시.
- **Windows + `better-sqlite3`**: 네이티브 컴파일이 필요하므로 `node-gyp` / Visual Studio Build Tools가 없으면 설치 실패. 막히면 대안으로 `@libsql/client`로 전환 검토 (PRD 외 변경이라 사용자 승인 필요).
- **DB 클라이언트는 글로벌 싱글턴**: Next.js dev 서버의 HMR이 모듈을 재실행하므로 `globalThis.__db__` 패턴 사용 (Prisma 권장 패턴과 동일).
- **JWT_SECRET**: `.env.local`에서 로드. 길이 32바이트 이상 권장. 부재 시 부팅 시 에러 throw (조용히 빈 문자열로 동작하지 않게).
- **`localStorage` 접근**: 클라이언트 컴포넌트에서만. SSR과 충돌하지 않도록 `useEffect` 안에서 또는 `'use client'` 컴포넌트에서만 접근.

### 4. 구현 순서 근거

**의존성 그래프 (위→아래로 빌드)**
```
DB schema ─► DB client ─► (마이그레이션 실행)
              │
              ▼
  validators.ts ─► auth.ts ─► response.ts
                                  │
                                  ▼
                     /api/auth/* ─► /api/lists/* + /api/categories/* ─► /api/todos/*
                                                                            │
                                                                            ▼
                                                              api-client.ts (클라)
                                                                            │
                                                                            ▼
                                                  /login + /register ─► /(메인) + 컴포넌트
                                                                            │
                                                                            ▼
                                                                    Playwright E2E
```
- **상위 의존부터 만든다**: `auth.ts`가 `response.ts`를 쓰니 response가 먼저, validators는 양쪽이 쓰니 가장 먼저.
- **각 핸들러는 curl로 즉시 검증**한 뒤 다음으로 넘어간다 (UI까지 기다리지 않음). 회귀 발견을 빠르게.
- **단계 1 끝까지 UI 0줄**: 백엔드 안정화 우선. UI 작업 중 API 결함 발견 시 컨텍스트 스위칭 비용이 크다.

### 5. 데모 친화 결정

- **첫 시연용 시드 사용자/Todo는 만들지 않는다**: 데모는 빈 화면에서 회원가입부터 시작해야 청중이 흐름을 이해함.
- **에러 메시지는 한국어**: PRD/UI 톤과 일치. 코드(`VALIDATION_FAILED`)는 영문 유지(개발자 가독성).
- **로깅 포맷**: `[ISO][LEVEL][method] path → status (Xms) userId=N` 한 줄. grep으로 핸들러 추적 용이.

---

## 단계 0 — 셋업

| # | 작업 | 산출물 | 검증 |
|---|------|--------|------|
| 0-1 | Node.js 20+ / pnpm 설치 확인 | `node -v`, `pnpm -v` | 버전 출력 |
| 0-2 | `pnpm create next-app@latest` 실행 (TS / App Router / Tailwind / ESLint / src dir / import alias `@/*`) | 프로젝트 루트 골격 | `pnpm dev` 시 기본 페이지 |
| 0-3 | `.gitignore`에 `data/`, `logs/`, `.env.local` 추가 | `.gitignore` | grep으로 확인 |
| 0-4 | `.env.local.example` 작성 (`JWT_SECRET`, `DATABASE_URL=file:./data/app.db`) | `.env.local.example` | 파일 존재 |
| 0-5 | shadcn/ui 초기화 (`pnpm dlx shadcn@latest init` — 다크모드 활성화) | `components.json`, `src/components/ui/` | `Button` 컴포넌트 추가 테스트 |

---

## 단계 1 — 백엔드 + 데이터

### 1-A. DB / ORM 셋업

| # | 작업 | 파일 |
|---|------|------|
| 1-A-1 | 의존성 설치: `drizzle-orm`, `better-sqlite3`, `drizzle-kit`, `@types/better-sqlite3` | `package.json` |
| 1-A-2 | Drizzle 설정 파일 작성 | [drizzle.config.ts](../drizzle.config.ts) |
| 1-A-3 | 스키마 정의 (PRD §6 그대로 — `users`, `todo_lists`, `categories`, `todos` + 인덱스 3개) | [src/db/schema.ts](../src/db/schema.ts) |
| 1-A-4 | DB 클라이언트 (싱글턴) | [src/db/client.ts](../src/db/client.ts) |
| 1-A-5 | `package.json` scripts 추가: `db:generate`, `db:migrate`, `db:studio` | `package.json` |
| 1-A-6 | 마이그레이션 생성 + 실행 → `data/app.db` 생성 확인 | `src/db/migrations/` |

**DoD**: `pnpm db:studio`로 4개 테이블이 비어 있는 상태로 보임.

### 1-B. 인증 모듈

| # | 작업 | 파일 |
|---|------|------|
| 1-B-1 | 의존성 설치: `jose`, `bcryptjs`, `@types/bcryptjs`, `zod` | `package.json` |
| 1-B-2 | Zod 검증 스키마 정의 (회원가입/로그인/Todo/List/Category 입력) | [src/lib/validators.ts](../src/lib/validators.ts) |
| 1-B-3 | `hashPassword`, `verifyPassword` (bcryptjs) | [src/lib/auth.ts](../src/lib/auth.ts) |
| 1-B-4 | `signToken(userId)` (24h 만료, jose), `verifyToken(token)` | 같은 파일 |
| 1-B-5 | `requireAuth(request)` 헬퍼 — `Authorization: Bearer` 파싱 → `userId` 반환 또는 `401` 응답 객체 | 같은 파일 |
| 1-B-6 | API 응답 헬퍼: `ok(data, status?)`, `fail(code, message, status)` | [src/lib/response.ts](../src/lib/response.ts) |

### 1-C. Auth Route Handlers

| # | 메서드 | 경로 | 파일 |
|---|--------|------|------|
| 1-C-1 | POST | `/api/auth/register` | [src/app/api/auth/register/route.ts](../src/app/api/auth/register/route.ts) |
| 1-C-2 | POST | `/api/auth/login` | [src/app/api/auth/login/route.ts](../src/app/api/auth/login/route.ts) |
| 1-C-3 | GET  | `/api/auth/me` | [src/app/api/auth/me/route.ts](../src/app/api/auth/me/route.ts) |

**검증**: `curl`로 가입 → 로그인 → `/me` 호출 흐름 통과.

### 1-D. Lists / Categories Route Handlers

| # | 메서드 | 경로 | 파일 |
|---|--------|------|------|
| 1-D-1 | GET, POST | `/api/lists` | [src/app/api/lists/route.ts](../src/app/api/lists/route.ts) |
| 1-D-2 | PATCH, DELETE | `/api/lists/[id]` | [src/app/api/lists/[id]/route.ts](../src/app/api/lists/[id]/route.ts) |
| 1-D-3 | GET, POST | `/api/categories` | [src/app/api/categories/route.ts](../src/app/api/categories/route.ts) |
| 1-D-4 | PATCH, DELETE | `/api/categories/[id]` | [src/app/api/categories/[id]/route.ts](../src/app/api/categories/[id]/route.ts) |

각 핸들러는 **무조건 `requireAuth` 통과 후 `userId`로 소유권 검증** (다른 사용자의 리소스 접근 시 `404` 응답).

### 1-E. Todos Route Handlers

| # | 메서드 | 경로 | 비고 |
|---|--------|------|------|
| 1-E-1 | GET | `/api/todos` | 쿼리 파라미터 `q`, `list_id`, `category_id`, `priority`, `is_completed`, `sort` 지원 |
| 1-E-2 | POST | `/api/todos` | 생성 시 `userId` 강제 주입 |
| 1-E-3 | PATCH | `/api/todos/[id]` | 완료 토글 / 제목 / 설명 / 우선순위 / 마감일 / 카테고리 / 리스트 변경 — `updatedAt` 갱신 |
| 1-E-4 | DELETE | `/api/todos/[id]` | 소유권 검증 |

### 1-F. 관찰성 + 품질

| # | 작업 | 파일 |
|---|------|------|
| 1-F-1 | 요청/에러 로거 (`logs/app.log` + 콘솔) | [src/lib/logger.ts](../src/lib/logger.ts) |
| 1-F-2 | 모든 Route Handler에서 진입/에러 로깅 적용 | (각 route.ts) |
| 1-F-3 | `pnpm typecheck`, `pnpm lint` 무에러 | — |
| 1-F-4 | curl 시나리오 스크립트 (선택) | `scripts/smoke.sh` |

**단계 1 DoD**
- `pnpm dev` 한 줄로 기동
- curl로 회원가입 → 로그인 → JWT 획득 → Todo CRUD + 필터/정렬 전 흐름 동작
- 다른 사용자 토큰으로 내 Todo 접근 시 404
- `pnpm typecheck && pnpm lint` 무에러

---

## 단계 2 — UI + 통합

### 2-A. 클라이언트 인프라

| # | 작업 | 파일 |
|---|------|------|
| 2-A-1 | 의존성: `@tanstack/react-query`, `react-hook-form`, `@hookform/resolvers` | `package.json` |
| 2-A-2 | TanStack Query Provider | [src/app/providers.tsx](../src/app/providers.tsx) |
| 2-A-3 | 루트 레이아웃에서 Provider 감싸기 + 다크모드 클래스 적용 | [src/app/layout.tsx](../src/app/layout.tsx) |
| 2-A-4 | fetch 래퍼 (`localStorage.token` 자동 주입, 401 시 로그아웃 + `/login` 리다이렉트) | [src/lib/api-client.ts](../src/lib/api-client.ts) |
| 2-A-5 | Query 키 컨벤션 정리 (`['todos', filters]`, `['lists']`, `['categories']`) | (api-client에 함께) |

### 2-B. 인증 화면

| # | 작업 | 파일 |
|---|------|------|
| 2-B-1 | `/login` 페이지 (react-hook-form + Zod) | [src/app/login/page.tsx](../src/app/login/page.tsx) |
| 2-B-2 | `/register` 페이지 | [src/app/register/page.tsx](../src/app/register/page.tsx) |
| 2-B-3 | 보호 라우트 가드 컴포넌트 — `localStorage.token` 부재 시 `router.replace('/login')` | [src/components/AuthGuard.tsx](../src/components/AuthGuard.tsx) |

### 2-C. 메인 화면 컴포넌트

| # | 컴포넌트 | 파일 |
|---|---------|------|
| 2-C-1 | `Sidebar` (사용자명, 리스트 목록, 카테고리 목록, 다크모드 토글, 로그아웃) | [src/components/Sidebar.tsx](../src/components/Sidebar.tsx) |
| 2-C-2 | `SearchFilterBar` (검색바, 필터, 정렬 드롭다운) | [src/components/SearchFilterBar.tsx](../src/components/SearchFilterBar.tsx) |
| 2-C-3 | `TodoList` (필터 상태 → `useQuery`로 fetch) | [src/components/TodoList.tsx](../src/components/TodoList.tsx) |
| 2-C-4 | `TodoItem` (체크박스 + 제목 + 우선순위 뱃지 + 마감일 + ⋯ 메뉴) | [src/components/TodoItem.tsx](../src/components/TodoItem.tsx) |
| 2-C-5 | `NewTodoInput` (Enter로 즉시 생성, 낙관적 업데이트) | [src/components/NewTodoInput.tsx](../src/components/NewTodoInput.tsx) |
| 2-C-6 | `TodoEditDialog` (shadcn `Dialog` + 모든 필드 편집) | [src/components/TodoEditDialog.tsx](../src/components/TodoEditDialog.tsx) |
| 2-C-7 | `ThemeToggle` (`localStorage.theme`, `<html>` 클래스 토글) | [src/components/ThemeToggle.tsx](../src/components/ThemeToggle.tsx) |
| 2-C-8 | `/` 메인 페이지 — 위 컴포넌트 조립 + `AuthGuard` 적용 | [src/app/page.tsx](../src/app/page.tsx) |

### 2-D. 낙관적 업데이트

- `NewTodoInput`: `onMutate`에서 캐시에 임시 항목 추가 → 실패 시 롤백
- `TodoItem` 완료 토글: 같은 패턴
- 우선순위 뱃지 색상: high=red, medium=yellow, low=green (PRD §8 시안 기준)

### 2-E. E2E + 데모 준비

| # | 작업 | 파일 |
|---|------|------|
| 2-E-1 | `@playwright/test` 설치 + `playwright.config.ts` | `playwright.config.ts` |
| 2-E-2 | E2E 시나리오: 회원가입 → 로그인 → Todo 생성 → 완료 토글 → 삭제 | [tests/e2e/todo-flow.spec.ts](../tests/e2e/todo-flow.spec.ts) |
| 2-E-3 | (선택) `docker-compose.yml` — Node 컨테이너 + 볼륨 마운트 | `docker-compose.yml` |
| 2-E-4 | [docs/tutorial.md](./tutorial.md) 채우기 — 데모 진행 순서, 화면 캡처 자리, 발표용 멘트 | `docs/tutorial.md` |

**단계 2 DoD**
- 브라우저에서 회원가입 → 로그인 → Todo 생성/완료/수정/삭제 + 검색/필터/정렬 동작
- Playwright 시나리오 통과
- 새로고침 후에도 데이터 유지
- 다크/라이트 모드 토글 동작

---

## 핵심 파일 트리 (생성 예정)

```
src/
├── app/
│   ├── api/
│   │   ├── auth/{register,login,me}/route.ts
│   │   ├── lists/route.ts, lists/[id]/route.ts
│   │   ├── categories/route.ts, categories/[id]/route.ts
│   │   └── todos/route.ts, todos/[id]/route.ts
│   ├── login/page.tsx, register/page.tsx
│   ├── page.tsx, layout.tsx, providers.tsx
├── components/
│   ├── ui/ (shadcn)
│   └── AuthGuard, Sidebar, SearchFilterBar, TodoList, TodoItem,
│       NewTodoInput, TodoEditDialog, ThemeToggle
├── lib/
│   ├── auth.ts, api-client.ts, validators.ts, response.ts, logger.ts
└── db/
    ├── schema.ts, client.ts, migrations/
data/app.db          (gitignore)
logs/app.log         (gitignore)
tests/e2e/todo-flow.spec.ts
drizzle.config.ts, playwright.config.ts
.env.local.example
```

---

## 검증 방식 (End-to-End)

### 1. 단계 1 — 해피 패스 (터미널)
```sh
pnpm dev &
curl -X POST http://localhost:3000/api/auth/register -H "Content-Type: application/json" -d '{"username":"demo","password":"demo1234"}'
TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login -H "Content-Type: application/json" -d '{"username":"demo","password":"demo1234"}' | jq -r .data.token)
curl -X POST http://localhost:3000/api/todos -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"title":"첫 할 일","priority":"high"}'
curl -H "Authorization: Bearer $TOKEN" "http://localhost:3000/api/todos?priority=high&sort=due_date"
```

### 2. 단계 1 — 네거티브 케이스 (구현 전략 §2 패턴 검증)
| 케이스 | 기대 응답 |
|--------|----------|
| 토큰 없이 `/api/todos` GET | `401 { error: { code: "UNAUTHENTICATED" } }` |
| 잘못된 토큰 (`Bearer xxx`) | `401 UNAUTHENTICATED` |
| `title` 누락 POST | `400 { error: { code: "VALIDATION_FAILED" } }` |
| 같은 username 재등록 | `409 { error: { code: "CONFLICT" } }` |
| 다른 사용자(=demo2) 토큰으로 demo의 Todo `id`를 PATCH | `404 NOT_FOUND` (403 아님) |
| 다른 사용자 토큰으로 GET `/api/todos` | demo의 Todo 절대 미포함 |

### 3. 단계 2 — 브라우저 + Playwright
- PRD §8 시안대로 사이드바 + 메인 + 검색/필터/정렬 동작.
- `pnpm exec playwright test` — 회원가입 → 로그인 → Todo 생성 → 완료 토글 → 삭제 시나리오 통과.
- 새로고침 후 데이터/로그인 상태 유지.
- 다크/라이트 토글 + `localStorage.theme` 영속화.

### 4. 데모 회귀 시나리오 (단계 2 끝나고 1회 손으로 돌려보기)
1. demo / demo2 두 계정 동시 로그인 (다른 브라우저 프로파일).
2. demo가 Todo 생성 → demo2 화면에 절대 안 보임.
3. demo가 카테고리 삭제 → 관련 Todo는 살아 있고 `categoryId`만 null.
4. JWT 만료 시뮬레이션 (`localStorage.token`을 손상된 값으로) → 다음 API 호출에서 자동 로그아웃 + `/login` 리다이렉트.

---

## 추적 방법 제안

- 이 문서의 각 표 행을 진행하면서 `[ ]` → `[x]`로 체크해도 되고, 작업 단위로 commit 메시지에 `task: 1-A-3` 형태로 참조해도 좋음.
- 데모 시점에 어떤 단계에서 멈춰 있는지 한눈에 파악할 수 있도록, 이 문서를 PR 설명/슬라이드의 진행률 트래커로 활용.
