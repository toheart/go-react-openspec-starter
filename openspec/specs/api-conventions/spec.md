## Purpose

Define the baseline API contract requirements shared by repository-owned HTTP endpoints.
## Requirements
### Requirement: HTTP APIs must use explicit versioned routes
Repository-owned HTTP APIs MUST expose versioned routes so that breaking changes can be managed safely.

#### Scenario: Registering a new HTTP endpoint
- **WHEN** a new backend API endpoint is introduced
- **THEN** its route MUST live under a versioned prefix such as `/api/v1/`
- **AND** breaking changes MUST be introduced through a new version rather than silently changing the existing contract

### Requirement: JSON responses must use the shared envelope
Backend API responses MUST follow one unified response structure.

#### Scenario: Returning a successful response
- **WHEN** an endpoint returns success data
- **THEN** the JSON body MUST include `code`, `message`, and `data`
- **AND** `code` MUST be `0`
- **AND** `message` MUST use the shared success value `success`

#### Scenario: Returning a paginated response
- **WHEN** an endpoint returns paginated data
- **THEN** the response MUST include the standard envelope fields
- **AND** the response MUST include a `page` object with `page`, `pageSize`, `total`, and `pages`

#### Scenario: Returning an error response
- **WHEN** an endpoint returns an error
- **THEN** the JSON body MUST include a business `code` and a human-readable `message`
- **AND** the response MUST include `detail` when extra debugging or validation context is returned to the client

### Requirement: Pagination inputs must be normalized
Paginated endpoints MUST apply shared pagination semantics.

#### Scenario: Accepting pagination query parameters
- **WHEN** an endpoint supports pagination
- **THEN** `page` MUST be one-based with a default of `1`
- **AND** `pageSize` MUST default to `20`
- **AND** `pageSize` MUST NOT exceed `100` unless the spec for that capability states otherwise

### Requirement: Swagger annotations must document handler behavior
Public HTTP handlers MUST remain machine-documentable through Swagger annotations.

#### Scenario: Adding or modifying a public handler
- **WHEN** a handler is created or changed for a documented API
- **THEN** Swagger annotations MUST be updated together with the implementation
- **AND** the handler annotations MUST include `@Summary`, `@Tags`, `@Accept`, `@Produce`, `@Success`, `@Failure`, and `@Router`
- **AND** handlers with path, query, body, or header inputs MUST declare matching `@Param` annotations
- **AND** authenticated handlers MUST declare `@Security` annotations
- **AND** the path in `@Router` MUST be relative to `@BasePath` and MUST NOT repeat the `/api/v1` prefix
- **AND** generated API docs under `backend/docs/` MUST be treated as generated output rather than hand-edited source

#### Scenario: Generating repository Swagger documentation
- **WHEN** Swagger documentation is generated or regenerated
- **THEN** the repository MUST use `swaggo/swag`
- **AND** the generated output MUST be written under `backend/docs/`
- **AND** the Swagger UI route MUST remain exposed through `GET /swagger/*any`

#### Scenario: Configuring API metadata for Swagger generation
- **WHEN** a backend service configures repository-owned Swagger documentation
- **THEN** `backend/cmd/server/main.go` MUST declare the API metadata annotations for title, version, description, host, `@BasePath`, and schemes
- **AND** the configured `@BasePath` MUST match the active versioned API prefix

### Requirement: Business error codes must follow shared repository ranges
Repository-owned HTTP APIs MUST allocate business error codes from the shared numbering scheme so clients can interpret errors consistently across modules.

#### Scenario: Introducing a new business error code
- **WHEN** a backend module defines or returns a new business error code
- **THEN** the code MUST follow the `XXYYYY` format
- **AND** `XX` MUST identify a module range between `10` and `99`
- **AND** `YYYY` MUST identify a module-local sequence between `0001` and `9999`
- **AND** shared common errors MUST remain in the `10XXXX` range

### Requirement: Shared API response helpers must preserve canonical field names
Repository-owned HTTP APIs MUST keep shared response helpers and DTOs aligned with the canonical response envelope.

#### Scenario: Adding or updating shared response helpers
- **WHEN** shared response wrapper types or helper functions are introduced or changed
- **THEN** success helpers MUST emit `code`, `message`, and `data`
- **AND** paginated helpers MUST emit the canonical `page` shape with `page`, `pageSize`, `total`, and `pages`
- **AND** error helpers MUST preserve `code`, `message`, and optional `detail`

