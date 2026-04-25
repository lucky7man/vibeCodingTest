$ErrorActionPreference = 'Stop'
$env:Path += ";$env:ProgramFiles\GitHub CLI"
$repo = 'lucky7man/vibeCodingTest'

function New-Issue($title, $body) {
    Write-Host "Creating: $title"
    $url = $body | gh issue create --repo $repo --title $title --body-file -
    Write-Host "  -> $url"
}

# ---- #1 단계 0 ----
$body = @'
## 작업내용
- Node.js 20+ / pnpm 설치 확인
- `pnpm create next-app@latest .` (TS / App Router / Tailwind / ESLint / src dir / import alias `@/*`)
- `.gitignore` 보강: `data/`, `logs/`, `.env.local` 포함 확인
- `.env.local.example` 작성 (`JWT_SECRET`, `DATABASE_URL=file:./data/app.db`)
- shadcn/ui 초기화 (`pnpm dlx shadcn@latest init`, 다크모드 활성화)

## 작업목적
이후 모든 단계가 의존하는 빈 캔버스를 마련한다. 첫 파일을 만들기 전에 의존성·스타일·디렉토리 구조를 못 박아 일관성을 확보하기 위함.

## 인수조건 (AC)
- [ ] `pnpm dev` 실행 시 Next.js 기본 페이지가 `http://localhost:3000`에서 응답
- [ ] `pnpm dlx shadcn@latest add button` 실행 후 `src/components/ui/button.tsx` 생성됨
- [ ] `.env.local.example`에 `JWT_SECRET`과 `DATABASE_URL` 두 키 모두 존재
- [ ] `.gitignore`에 `data/`, `logs/`, `.env.local` 모두 포함
- [ ] `pnpm typecheck`, `pnpm lint` 무에러

## 의존성
- 없음 (시작점)

---
참고: [docs/tasks.md](../blob/main/docs/tasks.md) 단계 0
'@
New-Issue '[단계 0] 프로젝트 초기 셋업 (Next.js + Tailwind + shadcn/ui)' $body

# ---- #2 1-A ----
$body = @'
## 작업내용
- 의존성 설치: `drizzle-orm`, `better-sqlite3`, `drizzle-kit`, `@types/better-sqlite3`
- `drizzle.config.ts` 작성
- `src/db/schema.ts` — PRD §6 그대로 (`users`, `todo_lists`, `categories`, `todos` + 인덱스 3개)
- `src/db/client.ts` — `globalThis.__db__` 싱글턴 패턴 (HMR 안전)
- `package.json` scripts 추가: `db:generate`, `db:migrate`, `db:studio`
- 마이그레이션 생성 + 실행 → `data/app.db` 생성 확인

## 작업목적
모든 핸들러가 의존하는 데이터 계층을 가장 먼저 안정화한다. 스키마가 흔들리면 위 계층 전부 재작업 비용이 큼.

## 인수조건 (AC)
- [ ] `pnpm db:studio`로 4개 테이블이 빈 상태로 표시됨
- [ ] 인덱스 3개(`idx_todos_user_id`, `idx_todos_due_date`, `idx_todos_is_completed`) 생성 확인
- [ ] FK `onDelete: 'cascade'` (todo_lists/categories→users), `set null` (todos.listId/categoryId) 동작
- [ ] HMR 시 DB 인스턴스가 재생성되지 않음 (싱글턴 검증)
- [ ] `data/app.db` 파일이 `.gitignore`로 제외됨

## 의존성
- #1 (단계 0 셋업 완료)

---
참고: [docs/tasks.md](../blob/main/docs/tasks.md) 1-A
'@
New-Issue '[1-A] DB / ORM 셋업 (Drizzle + SQLite + 마이그레이션)' $body

# ---- #3 1-B ----
$body = @'
## 작업내용
- 의존성 설치: `jose`, `bcryptjs`, `@types/bcryptjs`, `zod`
- `src/lib/validators.ts` — 회원가입/로그인/Todo/List/Category 입력 Zod 스키마 + `z.infer` 타입 export
- `src/lib/auth.ts`
  - `hashPassword` / `verifyPassword` (bcryptjs)
  - `signToken(userId)` / `verifyToken(token)` (jose, HS256, 24h, payload `{ sub: String(userId) }`)
  - `requireAuth(request)` — `Authorization: Bearer` 파싱 → `userId` 반환 또는 `401` 응답 객체
- `src/lib/response.ts` — `ok(data, status?)` / `fail(code, message, status)` (`{ data }` / `{ error: { code, message } }`)

## 작업목적
모든 Route Handler가 공통으로 쓰는 인증·검증·응답 토대. 여기서 패턴이 흔들리면 핸들러마다 다른 스타일이 양산되어 데모/유지보수가 어려워진다.

## 인수조건 (AC)
- [ ] `JWT_SECRET` 부재 시 모듈 로딩 단계에서 throw
- [ ] `signToken(1)` → `verifyToken` 결과가 `{ sub: '1' }` 포함, `exp`가 약 24h 후
- [ ] `requireAuth`가 잘못된 토큰에 대해 401 응답 객체 반환 (예외를 throw하지 않음)
- [ ] Zod 스키마는 `z.infer`로 타입 export 되어 라우트와 폼이 같은 타입 사용
- [ ] 에러 코드 5종(`VALIDATION_FAILED`/`UNAUTHENTICATED`/`NOT_FOUND`/`CONFLICT`/`INTERNAL`) 응답 포맷 일치

## 의존성
- #2 (1-A DB 클라이언트 사용)

---
참고: [docs/tasks.md](../blob/main/docs/tasks.md) 1-B
'@
New-Issue '[1-B] 인증 모듈 (jose JWT + bcryptjs + Zod + 응답 헬퍼)' $body

# ---- #4 1-C ----
$body = @'
## 작업내용
- POST `/api/auth/register` — username 중복 시 `409 CONFLICT`, 성공 시 `201 { data: { id, username } }`
- POST `/api/auth/login` — 실패 시 `401 UNAUTHENTICATED`, 성공 시 `200 { data: { token } }`
- GET `/api/auth/me` — JWT의 userId로 사용자 조회, `200 { data: { id, username } }`
- 모든 핸들러 상단에 `export const runtime = 'nodejs';` 명시

## 작업목적
회원가입/로그인 플로우를 검증한다. 이후 모든 인증 엔드포인트의 토큰 발급원이므로 여기가 잘 되어야 후속 작업이 시작 가능.

## 인수조건 (AC)
- [ ] curl로 register → login → /me 흐름 통과
- [ ] 같은 username 재등록 시 409 CONFLICT
- [ ] 잘못된 비밀번호 로그인 시 401 UNAUTHENTICATED
- [ ] 비밀번호 누락 등 검증 실패 시 400 VALIDATION_FAILED
- [ ] DB의 `users.password`는 bcrypt 해시 (평문 저장 금지)

## 의존성
- #3 (1-B 인증 모듈)

---
참고: [docs/tasks.md](../blob/main/docs/tasks.md) 1-C
'@
New-Issue '[1-C] Auth Route Handlers (/api/auth/register, login, me)' $body

# ---- #5 1-D ----
$body = @'
## 작업내용
- GET, POST `/api/lists`
- PATCH, DELETE `/api/lists/[id]`
- GET, POST `/api/categories`
- PATCH, DELETE `/api/categories/[id]`
- 모든 핸들러: `requireAuth` 통과 후 `userId` 필터로 쿼리 (소유권 검증)

## 작업목적
Todo가 참조할 부모 리소스(리스트·카테고리)를 마련한다. 단순한 리소스에서 소유권 검증 정형 패턴을 먼저 다듬어 Todo에서 그대로 재사용.

## 인수조건 (AC)
- [ ] 모든 핸들러가 `requireAuth` 통과 후 `where: and(eq(...), eq(userId, ...))` 적용
- [ ] 다른 사용자의 list/category id로 PATCH/DELETE 시 `404 NOT_FOUND` (403 아님)
- [ ] DELETE list 시 관련 todos의 `listId`가 NULL로 (cascade 아님, set null)
- [ ] DELETE category 시 관련 todos의 `categoryId`가 NULL로
- [ ] curl 다중 사용자 시나리오: A가 만든 list가 B의 GET /api/lists에 절대 안 보임

## 의존성
- #4 (1-C: 토큰 발급 가능해야 검증 가능)

---
참고: [docs/tasks.md](../blob/main/docs/tasks.md) 1-D
'@
New-Issue '[1-D] Lists / Categories Route Handlers' $body

# ---- #6 1-E ----
$body = @'
## 작업내용
- GET `/api/todos` — 쿼리 파라미터 `q`, `list_id`, `category_id`, `priority`, `is_completed`, `sort` 지원 (기본 정렬 `created_at` desc)
- POST `/api/todos` — 생성 시 `userId` 강제 주입 (요청 본문의 userId는 무시)
- PATCH `/api/todos/[id]` — 완료 토글/제목/설명/우선순위/마감일/카테고리/리스트 변경 + `updatedAt` 자동 갱신
- DELETE `/api/todos/[id]` — 소유권 검증

## 작업목적
앱의 핵심 도메인. UI가 사용할 모든 동작이 여기에 묶이므로, UI 시작 전에 모든 시나리오를 curl로 검증.

## 인수조건 (AC)
- [ ] 6종 쿼리 파라미터 모두 동작 (단일/조합 모두)
- [ ] PATCH 시 `updatedAt`이 새 timestamp로 갱신됨
- [ ] 다른 사용자 todo에 GET/PATCH/DELETE 시 404 NOT_FOUND
- [ ] POST 시 클라이언트가 보낸 `userId` 필드는 무시되고 토큰의 userId 사용
- [ ] curl로 시드 → 필터 → 정렬 → 토글 → 삭제 시나리오 통과
- [ ] `priority` 잘못된 값 → 400 VALIDATION_FAILED

## 의존성
- #5 (1-D: list/category가 있어야 외래키 시나리오 검증)

---
참고: [docs/tasks.md](../blob/main/docs/tasks.md) 1-E
'@
New-Issue '[1-E] Todos Route Handlers (CRUD + 필터/정렬)' $body

# ---- #7 1-F ----
$body = @'
## 작업내용
- `src/lib/logger.ts` — 콘솔 + `logs/app.log` 동시 기록, 포맷 `[ISO][LEVEL][method] path → status (Xms) userId=N`
- 모든 Route Handler에 진입/에러 로깅 적용 (try/catch 또는 wrapper)
- `pnpm typecheck`, `pnpm lint` 무에러 통과
- (선택) `scripts/smoke.sh` — 단계 1 검증 curl 시나리오 자동화

## 작업목적
단계 1 DoD 마무리. 이후 UI 작업 중 API 회귀가 발견되면 로그로 빠르게 추적할 수 있어야 함.

## 인수조건 (AC)
- [ ] `logs/app.log`에 요청 로그가 한 줄씩 누적
- [ ] 핸들러 내부에서 throw 발생 시 ERROR 라인이 로그에 남고 500 INTERNAL 응답
- [ ] `pnpm typecheck && pnpm lint` 둘 다 무에러
- [ ] `logs/`가 `.gitignore`로 제외됨
- [ ] (선택) smoke.sh 실행 시 모든 케이스 PASS

## 의존성
- #6 (1-E: 모든 핸들러 완성 후 일괄 로깅 적용)

---
참고: [docs/tasks.md](../blob/main/docs/tasks.md) 1-F
'@
New-Issue '[1-F] 관찰성 + 품질 게이트 (logger + typecheck + lint)' $body

# ---- #8 2-A ----
$body = @'
## 작업내용
- 의존성 설치: `@tanstack/react-query`, `react-hook-form`, `@hookform/resolvers`
- `src/app/providers.tsx` — TanStack Query Provider
- `src/app/layout.tsx` — Provider로 감싸기 + 다크모드 클래스 적용
- `src/lib/api-client.ts` — fetch 래퍼: `localStorage.token` 자동 주입, 401 응답 시 토큰 삭제 + `/login` 리다이렉트
- Query 키 컨벤션: `['auth','me']`, `['lists']`, `['categories']`, `['todos', filters]`

## 작업목적
모든 UI 컴포넌트가 사용할 데이터 패칭/캐싱 토대. 401 자동 처리로 토큰 만료 UX를 일관되게 처리.

## 인수조건 (AC)
- [ ] 토큰 없이 보호 API 호출 → 401 → `localStorage.token` 삭제 + `/login`으로 자동 이동
- [ ] 토큰 있을 때 모든 요청에 `Authorization: Bearer <token>` 자동 부착
- [ ] React Query 캐시 키가 컨벤션대로 일관 적용
- [ ] SSR 환경에서 Provider가 `'use client'`로 안전하게 동작

## 의존성
- #7 (1-F: 단계 1 DoD 충족 = 백엔드 안정 후 UI 시작)

---
참고: [docs/tasks.md](../blob/main/docs/tasks.md) 2-A
'@
New-Issue '[2-A] 클라이언트 인프라 (TanStack Query + fetch 래퍼)' $body

# ---- #9 2-B ----
$body = @'
## 작업내용
- `src/app/login/page.tsx` — react-hook-form + Zod (validators.ts 재사용)
- `src/app/register/page.tsx`
- `src/components/AuthGuard.tsx` — `localStorage.token` 부재 시 `router.replace('/login')`

## 작업목적
메인 화면 진입 전 사용자 식별을 확보하고 보호 라우트 가드를 일원화.

## 인수조건 (AC)
- [ ] 회원가입 성공 → `/login` 또는 `/`로 자동 이동
- [ ] 로그인 성공 → `localStorage.token` 저장 + `/`로 이동
- [ ] 토큰 없이 `/` 접근 → `/login`으로 자동 리다이렉트
- [ ] 잘못된 자격 입력 → 폼에 한국어 에러 표시
- [ ] Zod 스키마는 `validators.ts`의 것을 재사용 (단일 소스)

## 의존성
- #8 (2-A: api-client 사용)

---
참고: [docs/tasks.md](../blob/main/docs/tasks.md) 2-B
'@
New-Issue '[2-B] 인증 화면 (/login, /register, AuthGuard)' $body

# ---- #10 2-C ----
$body = @'
## 작업내용
- `src/components/Sidebar.tsx` — 사용자명, 리스트/카테고리 목록, 다크모드 토글, 로그아웃
- `src/components/SearchFilterBar.tsx` — 검색바, 필터, 정렬 드롭다운
- `src/components/TodoList.tsx` — 필터 상태 → `useQuery`로 fetch
- `src/components/TodoItem.tsx` — 체크박스 + 제목 + 우선순위 뱃지 + 마감일 + ⋯ 메뉴
- `src/components/NewTodoInput.tsx` — Enter로 즉시 생성
- `src/components/TodoEditDialog.tsx` — shadcn Dialog + 모든 필드 편집
- `src/components/ThemeToggle.tsx` — `localStorage.theme` 영속화 + `<html>` 클래스 토글
- `src/app/page.tsx` — 위 컴포넌트 조립 + AuthGuard 적용

## 작업목적
PRD §8 시안의 메인 화면을 구현한다. 데모의 핵심 가시 산출물.

## 인수조건 (AC)
- [ ] PRD §8 레이아웃과 동일 (좌측 사이드바 + 우측 메인)
- [ ] 검색/필터/정렬 변경 시 `TodoList`가 자동 리프레시 (Query 키 변경)
- [ ] 우선순위 뱃지 색상: high=red, medium=yellow, low=green
- [ ] 다크/라이트 토글 + 새로고침 후에도 선택 유지
- [ ] EditDialog에서 제목/설명/우선순위/마감일/카테고리/리스트 모두 편집 가능
- [ ] 사이드바에서 리스트·카테고리 추가/삭제 가능

## 의존성
- #9 (2-B: AuthGuard 사용)

---
참고: [docs/tasks.md](../blob/main/docs/tasks.md) 2-C
'@
New-Issue '[2-C] 메인 화면 컴포넌트 (Sidebar/TodoList/Item/Input/Dialog/Toggle)' $body

# ---- #11 2-D ----
$body = @'
## 작업내용
- `NewTodoInput`: `onMutate`에서 캐시에 임시 항목 추가 → 실패 시 롤백
- `TodoItem` 완료 토글: 같은 패턴 (`onMutate` / `onError` / `onSettled`)

## 작업목적
데모 시 체감 반응성을 끌어올린다. 네트워크 지연이 있어도 즉시 반영되어 보이도록.

## 인수조건 (AC)
- [ ] 새 Todo 입력 → Enter 즉시 화면에 추가됨 (서버 응답 대기 없이)
- [ ] API 실패 시 추가했던 항목이 사라지고 토스트로 에러 표시
- [ ] 완료 체크박스 클릭 즉시 반영 + 실패 시 롤백
- [ ] React Query `onMutate` / `onError` / `onSettled` 모두 구현
- [ ] 변이 후 `['todos']` 캐시가 정확히 무효화됨

## 의존성
- #10 (2-C: 컴포넌트 존재해야 패턴 적용)

---
참고: [docs/tasks.md](../blob/main/docs/tasks.md) 2-D
'@
New-Issue '[2-D] 낙관적 업데이트 (생성 + 완료 토글)' $body

# ---- #12 2-E ----
$body = @'
## 작업내용
- `@playwright/test` 설치 + `playwright.config.ts` (Next dev 서버 자동 기동)
- `tests/e2e/todo-flow.spec.ts` — 회원가입 → 로그인 → Todo 생성 → 완료 토글 → 삭제 시나리오
- (선택) `docker-compose.yml` — Node 컨테이너 + 볼륨 마운트
- `docs/tutorial.md` 채우기 — 데모 진행 순서, 핵심 프롬프트, 발표용 멘트, 화면 캡처 자리

## 작업목적
단계 2 DoD 마무리 + 라이브 데모용 스크립트 준비. 데모 당일 흐름이 끊기지 않도록.

## 인수조건 (AC)
- [ ] `pnpm exec playwright test` 무에러 통과
- [ ] 새로고침 후 데이터/로그인 상태 유지
- [ ] 다른 사용자 계정 동시 로그인 시 첫 사용자 todo 미노출 (수동 검증)
- [ ] JWT 손상 시뮬레이션 → 자동 로그아웃 + `/login` 이동
- [ ] `docs/tutorial.md`에 데모 진행 순서 + 발표용 멘트 정리

## 의존성
- #11 (2-D: 낙관적 업데이트까지 완성된 UI 위에서 E2E)

---
참고: [docs/tasks.md](../blob/main/docs/tasks.md) 2-E
'@
New-Issue '[2-E] E2E (Playwright) + 데모 준비 (tutorial.md)' $body

Write-Host ""
Write-Host "=== 생성된 이슈 목록 ==="
gh issue list --repo $repo --limit 20
