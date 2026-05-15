---
name: fastapi
description: >
  Use when building, debugging, reviewing, or refactoring FastAPI applications.
  Triggers: FastAPI routes, APIRouter, dependencies with Depends, request/response
  models, Pydantic schemas, SQLAlchemy session patterns, auth, middleware,
  exception handlers, background tasks, startup/shutdown hooks, and API tests.
  Focus on matching the repository's existing architecture and avoiding common
  async, validation, and database mistakes.
---

# FastAPI Skill

Build and modify FastAPI services in a way that fits the current repository instead of forcing a generic template.

## When To Use This Skill

Use this skill when the task involves any of these:

- FastAPI endpoints, routers, or application setup
- `Depends(...)` dependencies, auth, or request-scoped state
- Pydantic request/response models and validation behavior
- SQLAlchemy usage inside a FastAPI app
- middleware, exception handlers, lifespan hooks, or background tasks
- API bug fixes, error handling, or serialization issues
- tests for FastAPI apps using `TestClient`, `AsyncClient`, or similar

## Core Rule

Read the existing app structure first and copy its patterns.

Do not assume:

- app factory vs global `app`
- sync vs async endpoints
- Pydantic v1 vs v2 helpers
- SQLAlchemy sync vs async sessions
- where business logic belongs
- how auth, settings, and DB sessions are wired

FastAPI projects look similar on the surface and still differ in important details. Match what is already there unless there is a clear bug or the user asks for a broader redesign.

## First Pass Workflow

Before editing:

1. Find the app entrypoint, router registration, and dependency setup.
2. Identify the request/response schema style used in the repo.
3. Identify the DB session lifecycle and transaction pattern.
4. Check how errors are represented today.
5. Check existing tests around the same router or feature.

Prefer the smallest correct change.

## Endpoint Design Rules

- Keep route handlers thin. Put orchestration in the endpoint and keep data access or business rules in the existing service/repository pattern if the repo has one.
- Use explicit parameter typing for path, query, header, cookie, and body inputs.
- Prefer `response_model` or the repo's existing equivalent for stable output shapes.
- Return proper HTTP status codes instead of encoding failures in success payloads.
- Raise `HTTPException` or the project's custom exceptions instead of returning ad hoc error dictionaries.
- If the endpoint performs I/O, ensure the implementation matches the route style: async routes should await async I/O; avoid blocking sync calls inside async handlers.
- If the repo uses sync SQLAlchemy sessions, do not switch only one route to async as a drive-by change.

## Dependency Injection Rules

- Reuse existing dependencies for DB sessions, auth, settings, and current user lookup.
- Keep dependencies focused: auth/authz, resource lookup, and cross-cutting concerns are good dependency boundaries.
- Do not hide core write logic inside deeply nested dependencies when a normal function call is clearer.
- If a dependency yields a DB session, follow the repository's cleanup pattern exactly.

## Pydantic And Serialization

Detect which version and style the project uses, then stay consistent.

- If the project is on Pydantic v2, expect patterns like `model_validate`, `model_dump`, and `ConfigDict`.
- If the project is on Pydantic v1, expect `parse_obj`, `dict`, and `class Config`.
- Reuse existing base schemas when present.
- Separate input and output schemas when the repo already treats them differently.
- Avoid exposing ORM objects directly unless the repo intentionally does so with the correct config.
- Be careful with `datetime`, enums, decimals, UUIDs, and optional fields. Match existing serialization behavior.

## Database Rules

- Follow the repository's existing unit-of-work pattern for `commit`, `flush`, `refresh`, and `rollback`.
- Avoid accidental lazy-loading in response serialization after the session is closed.
- If related data must be returned, load it intentionally using the repo's existing eager-loading style.
- Keep transaction boundaries obvious.
- On write paths, ensure failures do not leave partially committed state.
- Do not introduce a repository/service abstraction if the project currently keeps logic close to routes and the change is small.

## Async Safety

Common FastAPI bugs come from mixing async and sync code incorrectly.

- Do not call blocking network or file operations directly inside async routes.
- Do not use sync DB sessions from newly introduced async helpers unless the repo already does so intentionally.
- If background work is small and the repo already uses `BackgroundTasks`, keep using it. Otherwise, do not invent a queueing architecture unless asked.
- Be careful with shared mutable module-level state.

## Error Handling

- Match the repo's existing error payload format.
- If the app has central exception handlers, use them instead of duplicating response formatting in endpoints.
- Distinguish validation errors, not found errors, auth failures, conflict errors, and unexpected server errors.
- Preserve useful detail for logs without leaking internals through public API responses.

## Auth And Security

- Reuse existing auth dependencies and permission checks.
- Do not weaken authorization while fixing unrelated endpoint logic.
- Treat user-controlled identifiers and filters carefully.
- Be cautious with partial updates so protected fields cannot be overwritten accidentally.
- Never log secrets, tokens, raw passwords, or sensitive headers.

## Testing Workflow

When changing FastAPI code, add or update focused tests when the repo has tests.

Check for:

- happy path behavior
- validation failures
- auth/authz failures
- not-found behavior
- response shape changes
- DB side effects for create/update/delete flows

Use the same testing style already in the repository:

- `TestClient` for sync patterns
- `httpx.AsyncClient` or the repo's async fixture pattern for async tests
- existing fixture strategy for DB setup, dependency overrides, and auth

Avoid rewriting the test harness unless the user asked for that specifically.

## Review Checklist

Before finishing, verify:

- route registration is correct
- type annotations are consistent
- dependency wiring still works
- status codes are intentional
- response models match actual returned data
- async/sync boundaries are safe
- DB session usage matches project patterns
- tests cover the changed behavior

## Preferred Editing Strategy

1. Read nearby routers, schemas, dependencies, and tests.
2. Make the minimal fix or feature change.
3. Update or add targeted tests.
4. Run the most relevant test subset first.
5. Run broader verification only if the project already has a standard command for it.

## Anti-Patterns To Avoid

- returning raw ORM objects when the project uses schemas
- adding brand new abstractions for a one-endpoint fix
- mixing sync and async DB/session patterns casually
- performing hidden commits in surprising places
- swallowing exceptions and returning vague 200 responses
- duplicating validation rules across endpoint, service, and schema layers without a reason
- introducing incompatible Pydantic helpers for the version in use

## Output Expectation

For FastAPI tasks, produce code that is:

- idiomatic for the existing codebase
- explicit in types and status codes
- safe around DB and async boundaries
- covered by focused tests when appropriate
- minimal in scope unless the user requests a redesign
