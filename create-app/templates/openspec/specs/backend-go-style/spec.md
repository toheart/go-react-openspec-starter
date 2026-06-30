## Purpose

Define the mandatory baseline conventions for Go backend code in this repository.
## Requirements
### Requirement: Go backend code must follow repository style rules
All Go code in the backend MUST follow the repository's shared style conventions so that code remains predictable and reviewable.

#### Scenario: Implementing or refactoring backend Go code
- **WHEN** an engineer adds or changes Go files under `backend/`
- **THEN** the code MUST pass repository linting with `golangci-lint`
- **AND** comments and log messages MUST be written in English
- **AND** identifiers MUST follow Go naming conventions using camelCase for unexported names and PascalCase for exported names
- **AND** code MUST prefer early returns and reduced nesting
- **AND** code MUST NOT introduce `panic`, `init()`, or mutable package-level state without explicit justification

#### Scenario: Organizing backend Go code for readability
- **WHEN** a file introduces exported functions, struct literals, or unexported globals
- **THEN** exported functions MUST appear before unexported helpers in call-sequence order where practical
- **AND** struct literals MUST use field names
- **AND** zero-value fields MUST be omitted from struct literals unless the zero value is required for clarity
- **AND** unexported global variables MUST use the `_` prefix
- **AND** the repository's soft line length limit of 99 characters MUST be treated as the default target

### Requirement: Backend errors and logs must be structured
The backend MUST use consistent error propagation and structured logging behavior.

#### Scenario: Returning an error from backend code
- **WHEN** a function returns an error to its caller
- **THEN** the error MUST be wrapped with `%w` when additional context is needed
- **AND** the same error MUST NOT be both logged and returned unless ownership is explicit at the boundary
- **AND** error variables MUST use the `Err` prefix while custom error types MUST use the `Error` suffix

#### Scenario: Writing a backend log entry
- **WHEN** backend code emits logs
- **THEN** it MUST use the shared `internal/logging` wrapper based on `log/slog`
- **AND** structured fields MUST be preferred over string concatenation
- **AND** the error field key MUST be named `error`
- **AND** the message MUST start in lowercase English and MUST NOT end with a period
- **AND** log levels MUST follow the repository's `DEBUG`, `INFO`, `WARN`, and `ERROR` conventions
- **AND** high-volume loop logging MUST be avoided unless it is intentionally limited or downgraded to debug output

### Requirement: Backend configuration must use file plus environment override
Configuration handling MUST support environment-specific files and environment variable overrides.

#### Scenario: Adding or changing configuration fields
- **WHEN** backend configuration is introduced or modified
- **THEN** configuration MUST be loaded through `spf13/viper`
- **AND** the canonical file format MUST be YAML using `config.<runMode>.yaml` naming where applicable
- **AND** `config.yaml` MUST remain the fallback file name
- **AND** environment variables MUST be able to override file values
- **AND** environment variable names MUST use the `PROJECTNAME_` prefix and `_` separators
- **AND** sensitive values such as passwords or keys MUST be injected from the environment rather than committed to the repository

### Requirement: Shared mutable data must be protected at boundaries
The backend MUST avoid accidental shared mutation across package or layer boundaries.

#### Scenario: Passing slices or maps across a boundary
- **WHEN** a slice or map crosses a package, layer, or ownership boundary
- **THEN** the callee or caller MUST copy the value when mutation could leak across the boundary

### Requirement: Backend Go code must apply shared core Go patterns
Backend Go code MUST follow the repository's selected core Go patterns so common concurrency, lifecycle, and API mistakes are avoided consistently.

#### Scenario: Verifying interface and resource-management behavior
- **WHEN** backend code introduces interface implementations, locks, or owned resources
- **THEN** interface implementations MUST support compile-time verification where practical
- **AND** zero-value mutexes MUST be preferred over heap-allocated mutex pointers
- **AND** slices and maps that cross ownership boundaries MUST be copied when mutation could leak across the boundary
- **AND** owned resources such as locks or files MUST be released with `defer` when that is the normal control-flow cleanup mechanism

#### Scenario: Defining enums or channels
- **WHEN** backend code introduces enum-like constants or buffered channels
- **THEN** enum-like constants MUST start from `iota + 1` when zero would be ambiguous
- **AND** channels MUST be unbuffered or size `1` unless another size is explicitly justified

#### Scenario: Starting background goroutines
- **WHEN** backend code starts a goroutine
- **THEN** the goroutine MUST have a predictable exit path

### Requirement: Backend code must follow shared performance and style defaults
Backend Go code MUST apply the repository's default performance and style rules unless a change documents a justified exception.

#### Scenario: Writing backend Go code with predictable data sizes or conversions
- **WHEN** code performs common type conversion or initializes maps and slices
- **THEN** it MUST prefer `strconv` over `fmt` for simple type conversion paths
- **AND** it MUST avoid repeated string-to-byte conversions when the result can be reused
- **AND** it MUST specify capacity when initializing maps or slices with a known size

#### Scenario: Writing backend Go code for readability
- **WHEN** code introduces structs, slices, or exported functions
- **THEN** nil slices MUST be treated as valid empty slices

