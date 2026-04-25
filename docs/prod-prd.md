# PRD 작성을 위한 사전 정보 정리

> MVP (Minimal Vibecoding Product) — Todo List 관리 앱  
> 바이브 코딩 학습 라이브 데모 프로젝트

---

## 1. 제품 목적 및 배경

### 결정된 사항
- [x] **프로젝트 성격**: 바이브 코딩(AI 보조 개발) 학습을 위한 라이브 데모
- [x] **앱 유형**: Todo List 관리 앱 (백엔드 + 프론트엔드)
- [x] **개발 방식**: MVP 우선, 점진적 확장
- [x] **데모 대상 청중**: 모든 사람 (개발자 입문자, 현직 개발자, 비개발자 포함)
- [x] **목표**: 잘 만든 앱이 아닌 "바이브 코딩 과정 시연" 자체가 목표
- [x] **배포**: 로컬 데모로 마무리 (클라우드 배포 없음)

---

## 2. 사용자 및 인증

### 결정된 사항
- [x] **로그인 방식**: 아이디(username) + 비밀번호
- [x] **회원가입**: 누구나 가능 (오픈 가입)
- [x] **세션 유지**: JWT 토큰
- [x] **멀티 유저**: 각 사용자는 자신의 Todo만 조회/관리
- [x] **소셜 로그인**: 제외 (MVP 복잡도 과다)
- [x] **비밀번호 찾기**: 제외 (이메일 인증 없으므로 불가, MVP 범위 아님)

---

## 3. 핵심 기능 범위 (Core Features)

### MVP 포함 기능
- [x] **Todo CRUD**: 생성 / 조회 / 수정 / 삭제
- [x] **완료 처리**: 체크박스로 완료 표시
- [x] **우선순위**: 높음 / 중간 / 낮음 3단계
- [x] **마감일(Due Date)**: 날짜 지정 (알림은 제외)
- [x] **카테고리 / 태그**: 분류 기능
- [x] **검색 및 필터**: 키워드 검색, 상태/우선순위 필터
- [x] **정렬**: 생성일, 마감일, 우선순위 기준
- [x] **Todo 그룹(리스트)**: 여러 목록 관리

### MVP 이후 기능
- [ ] 드래그 앤 드롭 순서 변경 (복잡도 높음)
- [ ] 팀 공유 / 협업
- [ ] 알림 (브라우저 푸시, 이메일)
- [ ] 반복 일정 Todo
- [ ] 파일 첨부

---

## 4. 기술 스택

> 풀스택 TypeScript 단일 앱 구조 — 솔로 2주 데모에 최적화 (한 언어, 타입 공유, 빠른 시연)

### 결정된 사항

#### 풀스택 프레임워크
- [x] **프레임워크**: Next.js 15 (App Router) + TypeScript
- [x] **백엔드**: Next.js Route Handlers (`app/api/.../route.ts`)
- [x] **API 방식**: REST API
- [x] **DB**: SQLite + Drizzle ORM (타입 안전 스키마, 마이그레이션 내장)
- [x] **인증**: JWT 직접 구현 (`jose`) + `bcryptjs` (해시)
- [x] **검증**: Zod (요청/폼 공통 스키마)

#### UI / 클라이언트
- [x] **스타일링**: Tailwind CSS
- [x] **UI 컴포넌트**: shadcn/ui (다크모드 기본 지원)
- [x] **상태/데이터 페칭**: TanStack Query (클라이언트 캐싱·낙관적 업데이트)
- [x] **폼**: react-hook-form + Zod 리졸버

#### 개발 도구
- [x] **패키지 매니저**: pnpm
- [x] **린팅/포맷**: ESLint + Prettier (Next.js 기본 + Tailwind 플러그인)
- [x] **E2E 테스트**: Playwright

#### 인프라
- [x] **실행 환경**: 로컬 데모 전용 (`pnpm dev` 한 줄)
- [x] **컨테이너화**: 선택 사항 — `docker-compose.yml` 옵션 제공 (필수 아님)
- [x] **환경 분리**: `.env.local` 파일로 dev 환경만 운영

---

## 5. 데이터 모델 개요

### 확정된 엔티티 (Drizzle ORM 스키마, SQLite 운영)

```ts
// src/db/schema.ts
import { sqliteTable, integer, text } from 'drizzle-orm/sqlite-core';
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
  color: text('color'),                                    // hex (#RRGGBB)
});

export const todos = sqliteTable('todos', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  userId: integer('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  listId: integer('list_id').references(() => todoLists.id, { onDelete: 'set null' }),
  categoryId: integer('category_id').references(() => categories.id, { onDelete: 'set null' }),
  title: text('title').notNull(),
  description: text('description'),
  isCompleted: integer('is_completed', { mode: 'boolean' }).notNull().default(false),
  priority: text('priority', { enum: ['high', 'medium', 'low'] }).notNull().default('medium'),
  dueDate: text('due_date'),                               // YYYY-MM-DD
  createdAt: text('created_at').default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text('updated_at').default(sql`CURRENT_TIMESTAMP`),
});
```

---

## 6. UI/UX 방향

### 결정된 사항
- [x] **디자인 톤**: 미니멀 + 다크모드 지원 (shadcn/ui 기본 테마 활용)
- [x] **반응형**: 데스크탑 전용 (모바일 대응 없음)
- [x] **레이아웃 참고**: Todoist 스타일 (사이드바 + 메인 리스트)
- [x] **언어**: 한국어 UI

---

## 7. MVP 경계 정의 (In vs Out)

| 기능 | MVP 포함? | 비고 |
|------|-----------|------|
| 회원가입 / 로그인 | ✅ 포함 | 이메일 인증 제외 |
| Todo CRUD | ✅ 포함 | |
| 완료 체크 | ✅ 포함 | |
| 우선순위 | ✅ 포함 | 3단계 |
| 마감일 | ✅ 포함 | 알림 제외 |
| 카테고리/태그 | ✅ 포함 | |
| 검색/필터 | ✅ 포함 | |
| Todo 그룹(리스트) | ✅ 포함 | |
| 정렬 | ✅ 포함 | |
| 소셜 로그인 | ❌ 이후 | |
| 비밀번호 찾기 | ❌ 이후 | |
| 드래그 정렬 | ❌ 이후 | 복잡도 높음 |
| 팀 공유 | ❌ 이후 | |
| 알림 기능 | ❌ 이후 | |

---

## 8. 성공 기준 (Success Criteria)

### 결정된 사항
- [x] **완성 기준**: 로그인한 사용자가 Todo를 생성·완료·삭제할 수 있고, 새로고침 후에도 데이터가 유지되는 상태
- [x] **성능 목표**: API 응답 500ms 이하, 동시 사용자 목표 없음 (데모용 단일 사용자 기준)
- [x] **코드 품질**: 테스트 커버리지 목표 없음. ESLint/Prettier 기본 설정 적용, 빌드 에러 없음 수준

---

## 9. 개발 일정 및 마일스톤

### 결정된 사항
- [x] **개발자**: 솔로
- [x] **1차 데모 목표**: 2주
- [x] **개발 단위**: 스프린트 (1주 단위 2회)

### 스프린트 계획

| 스프린트 | 기간 | 목표 |
|---------|------|------|
| Sprint 1 | 1주차 | Next.js 15 + Drizzle 초기 세팅, SQLite 스키마/마이그레이션, JWT 인증, Route Handlers로 Todo/List/Category CRUD API |
| Sprint 2 | 2주차 | shadcn/ui 기반 UI 구현 (사이드바·메인·다크모드), TanStack Query 연동, Playwright E2E 시나리오, 데모 준비 |

---

## 다음 단계

✅ **PRD 본문 작성 완료** → [docs/prd.md](./prd.md)

이 문서(`prod-prd.md`)는 사전 결정 기록으로 보관하며, 구현 단계에서는 `prd.md`를 단일 소스 오브 트루스로 참조합니다.
