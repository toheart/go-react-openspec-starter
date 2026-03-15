## Purpose

Define the mandatory baseline conventions for TypeScript and React code in the frontend.
## Requirements
### Requirement: Frontend TypeScript code must use consistent naming and typing
Frontend TypeScript and React code MUST follow the project's naming and type-safety conventions.

#### Scenario: Creating or updating TypeScript source files
- **WHEN** an engineer adds or modifies TypeScript or TSX files under `frontend/src/`
- **THEN** comments MUST be written in English
- **AND** variables and functions MUST use camelCase
- **AND** boolean values MUST use `is`, `has`, `can`, or `should` prefixes
- **AND** React components, classes, interfaces, and type aliases MUST use PascalCase
- **AND** interfaces MUST NOT use an `I` prefix
- **AND** constants MUST use UPPER_SNAKE_CASE where they are true constants
- **AND** new code MUST avoid `any` unless no practical typed alternative exists and the exception is documented
- **AND** shared type declarations MUST live in the same source file or in dedicated `.d.ts` files

#### Scenario: Naming frontend files
- **WHEN** an engineer creates or renames frontend source files
- **THEN** non-component TypeScript files MUST use camelCase file names
- **AND** React component files MUST use PascalCase file names
- **AND** test files MUST use the `.test.ts` or `.test.tsx` suffix as appropriate

#### Scenario: Choosing TypeScript type expressions
- **WHEN** a developer introduces obvious local value types or enum-like finite states
- **THEN** code MUST prefer type inference for obvious local values rather than redundant annotations
- **AND** code MUST prefer union types over `enum` when a string union can express the same contract clearly

### Requirement: Functions and async flows must stay explicit and predictable
Frontend logic MUST favor explicit return contracts and modern async handling.

#### Scenario: Implementing asynchronous frontend logic
- **WHEN** code performs asynchronous work
- **THEN** it MUST prefer `async` and `await`
- **AND** independent concurrent operations MUST use `Promise.all`
- **AND** errors MUST be normalized into predictable `Error`-like objects before surfacing to UI code

#### Scenario: Declaring shared functions and services
- **WHEN** an exported helper, shared function, or service function is added
- **THEN** its return type MUST be explicit

### Requirement: Frontend API access must go through shared service layers
Frontend components MUST avoid ad hoc network calls scattered across the UI tree.

#### Scenario: Calling backend APIs from the frontend
- **WHEN** a component needs backend data
- **THEN** the network request MUST be implemented in `frontend/src/services/` or another shared access layer
- **AND** the shared service layer MUST interpret the repository response envelope using typed result objects
- **AND** the shared service layer MUST treat non-zero response codes as typed client errors
- **AND** components MUST consume typed service results rather than building raw request details inline

### Requirement: Imports must preserve readability
Frontend modules MUST keep imports ordered in a stable way.

#### Scenario: Adding imports to a TypeScript file
- **WHEN** imports are added or rearranged
- **THEN** they MUST be grouped in this order: Node.js built-in modules, third-party libraries, then project-local modules
- **AND** blank lines MUST separate each import group

### Requirement: Frontend error handling must use predictable repository patterns
Frontend code MUST surface service and UI errors through predictable `Error`-based structures.

#### Scenario: Defining reusable frontend error handling
- **WHEN** a frontend module introduces reusable error types or error-handling helpers
- **THEN** custom error classes MUST extend `Error`
- **AND** stable names, codes, and optional detail fields MUST be preserved when they are part of the API contract
- **AND** helper functions that capture failures MUST return normalized `Error` instances for unknown thrown values

