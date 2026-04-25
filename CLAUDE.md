# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository nature

This is a **vibe-coding live demo project** — the goal is not to ship a production Todo app but to demonstrate building a full-stack TypeScript app together with an AI assistant in front of an audience. Two artifacts matter:

1. The **working app** (Todo MVP) being built incrementally.
2. The **demo narrative** captured in [docs/tutorial.md](docs/tutorial.md) — prompts and steps the audience can replay.

When making decisions, prefer choices that are **easy to demo and explain** over choices that are technically optimal but require lengthy justification.

## Source-of-truth documents

Read these before planning any non-trivial change — they encode decisions that should not be re-litigated:

- [docs/prd.md](docs/prd.md) — **승인된 PRD v1.0** (single source of truth). Stack, data model, REST API, UI flow, and Sprint DoD are all fixed here.
- [docs/prod-prd.md](docs/prod-prd.md) — pre-PRD decision log (the "why" behind the PRD). Reference when a choice in `prd.md` seems arbitrary.
- [docs/tutorial.md](docs/tutorial.md) — demo walkthrough; updated by the `/tutorial` command after each demo session.

## Planned architecture (not yet implemented)

The repo currently contains only planning docs — **no source code exists yet**. The PRD locks in the following architecture; future code should match it rather than diverge:

- **One Next.js 15 (App Router) + TypeScript app** serves both UI and REST API. No separate backend process.
- **API**: Route Handlers under `src/app/api/.../route.ts`. 15 endpoints across `auth` / `lists` / `categories` / `todos`. Response shape is `{ data }` on success, `{ error: { code, message } }` on failure.
- **DB**: SQLite single file at `data/app.db`, accessed via Drizzle ORM. Schema defined in `src/db/schema.ts` with 4 tables (`users`, `todo_lists`, `categories`, `todos`) — see [docs/prd.md §6](docs/prd.md).
- **Auth**: JWT via `jose` (24h expiry, `Authorization: Bearer`) + `bcryptjs` for password hashing. Every authenticated handler MUST verify resource ownership against the JWT's `userId` — this is the only mechanism enforcing per-user data isolation.
- **Validation**: Zod schemas in `src/lib/validators.ts`, shared between request validation and react-hook-form.
- **Client**: TanStack Query for server state + optimistic updates; shadcn/ui + Tailwind for UI; dark mode persisted in `localStorage.theme`. JWT lives in `localStorage.token` and is auto-injected by the fetch wrapper in `src/lib/api-client.ts`.

When the app exists, `pnpm dev` is expected to be the single command that starts everything.

## Execution plan

The PRD's Sprint sections are broken into ordered, executable tasks in the active plan file under `~/.claude/plans/` (when present). Reference task IDs like `1-A-3` in commit messages to keep the demo narrative trackable. Sprint boundaries:

- **Sprint 0**: Project init (`pnpm create next-app`), Tailwind/shadcn setup, `.env.local.example`.
- **Sprint 1** (week 1): DB schema, auth module, all 15 Route Handlers. DoD = full curl flow works, `pnpm typecheck && pnpm lint` passes.
- **Sprint 2** (week 2): UI pages, components, optimistic updates, Playwright E2E. DoD = browser flow + Playwright passes + dark mode works.

## Conventions

- **Language for user-facing copy and commit messages**: Korean (PRD, demo audience, and existing slash commands are all Korean).
- **Per-user data isolation is non-negotiable**: any new query touching `todos` / `lists` / `categories` MUST filter by `userId` from the JWT. Accessing another user's resource returns `404` (not `403`).
- **Don't add features outside the PRD's P0 list** without checking with the user — the demo's value comes from staying within scope.

## Slash commands defined for this repo

- `/commit` — staged commit workflow (see [.claude/commands/commit.md](.claude/commands/commit.md)). **Never bypass git hooks** (`--no-verify` is forbidden). Reference the GitHub issue number in the commit message.
- `/tutorial` — append the latest demo session's prompts to [docs/tutorial.md](docs/tutorial.md), pulling from the prompt history under `~/.claude/projects/<this project>/`.

## Git

- Local git identity is set on this repo only (`lucky7man <lucky7.dad@gmail.com>`); do not change it globally.
- Remote: `https://github.com/lucky7man/vibeCodingTest` (public). Default branch: `main`.
- `.claude/settings.local.json` is gitignored; everything else under `.claude/` is tracked so the demo's slash commands travel with the repo.
