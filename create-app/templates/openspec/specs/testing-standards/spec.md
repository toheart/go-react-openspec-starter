## Purpose

Define the baseline testing workflow and layering strategy for backend and frontend changes.
## Requirements
### Requirement: New behavior must follow a test-first workflow
Changes to repository behavior MUST be guided by tests before or alongside implementation.

#### Scenario: Implementing a new feature or fixing a bug
- **WHEN** behavior changes are introduced
- **THEN** tests MUST be written or updated first to describe the expected outcome
- **AND** the work MUST follow a red-green-refactor cycle

### Requirement: Go tests must stay close to the code they verify
Backend test files MUST remain colocated with the code they cover and use the project's Go testing toolchain conventions.

#### Scenario: Adding backend tests
- **WHEN** Go tests are created
- **THEN** they MUST live beside the source file using the `*_test.go` naming pattern
- **AND** Go behavior tests MUST use Ginkgo v2 with Gomega assertions
- **AND** public functions and methods that are added or changed MUST have corresponding tests

#### Scenario: Registering a Go test suite
- **WHEN** a package adds Ginkgo-based tests
- **THEN** the package MUST provide a `TestXxx` entrypoint that registers the Ginkgo fail handler and suite
- **AND** generated mocks MUST live in a `mocks/` subdirectory beside the source package

### Requirement: Testing strategy must match the architecture layer
The scope of tests MUST match the layer being verified.

#### Scenario: Testing domain logic
- **WHEN** a domain-layer unit is tested
- **THEN** the test MUST remain pure and avoid external dependencies
- **AND** repository interfaces MUST be mocked when isolation is required
- **AND** the layer MUST target the repository's high-coverage expectation for core logic

#### Scenario: Testing application-layer orchestration
- **WHEN** an application service is tested
- **THEN** infrastructure dependencies MUST be mocked or stubbed
- **AND** DTO mapping and orchestration behavior MUST be verified

#### Scenario: Testing infrastructure integrations
- **WHEN** infrastructure integration tests use real dependencies such as databases or files
- **THEN** the tests MUST clean up owned resources
- **AND** the tests MUST support being skipped in short or constrained environments

#### Scenario: Testing HTTP interfaces
- **WHEN** an HTTP endpoint is tested end-to-end in process
- **THEN** the test MUST validate request and response behavior using tools such as `httptest`
- **AND** the test MUST verify the shared response envelope where applicable

### Requirement: Frontend tests must exercise async and dependency boundaries clearly
Frontend tests MUST keep async behavior deterministic and isolate external dependencies.

#### Scenario: Selecting a frontend test framework
- **WHEN** a frontend test suite is configured for repository UI code
- **THEN** it MUST use Jest or Vitest

#### Scenario: Testing frontend async logic
- **WHEN** a frontend test covers asynchronous UI or service behavior
- **THEN** it MUST await observable state changes rather than relying on arbitrary sleeps
- **AND** external dependencies MUST be mocked through the testing framework or shared test doubles

### Requirement: Go test doubles must follow repository mock conventions
Backend tests MUST use the repository's standard mock generation conventions when interface-based isolation is needed.

#### Scenario: Generating mocks for Go interfaces
- **WHEN** a backend package needs generated mocks
- **THEN** mock files MUST be generated with `mockery`
- **AND** generated mocks MUST live in a `mocks/` subdirectory beside the source package
- **AND** the repository MUST keep mock generation configuration in `.mockery.yaml` under `backend/`

#### Scenario: Using generated mocks in Ginkgo tests
- **WHEN** generated mocks are used in Go tests
- **THEN** tests MUST prefer the typed `EXPECT()` API
- **AND** mock constructors MUST receive `GinkgoT()` when supported

#### Scenario: Using lightweight handwritten mocks
- **WHEN** a test only needs a simple helper double that does not justify generation
- **THEN** a handwritten mock MUST remain limited to that local testing case

### Requirement: Test execution commands must remain standardized
Repository test workflows MUST expose stable commands for backend and frontend contributors.

#### Scenario: Running repository tests
- **WHEN** contributors run the standard test workflows
- **THEN** backend tests MUST remain runnable through `make test`
- **AND** Go package and coverage runs MUST remain compatible with `ginkgo`
- **AND** short-mode backend test runs MUST remain compatible with `go test -short ./...`
- **AND** mock generation MUST remain runnable through `make mock`
- **AND** frontend tests MUST remain runnable through `npm test`
- **AND** frontend coverage runs MUST remain runnable through `npm run test:coverage`

### Requirement: Test cases must follow repository best practices
Repository test cases MUST remain readable, isolated, and deterministic.

#### Scenario: Structuring individual tests
- **WHEN** a contributor writes or updates repository tests
- **THEN** test names MUST describe the expected behavior
- **AND** each `It` block MUST verify exactly one behavior
- **AND** shared setup MUST use `BeforeEach`
- **AND** tests MUST remain independent and MUST NOT share mutable state across `It` blocks

#### Scenario: Avoiding test anti-patterns
- **WHEN** a contributor implements repository tests
- **THEN** tests MUST NOT rely on `time.Sleep`
- **AND** tests MUST NOT ignore error return values
- **AND** tests MUST NOT test private functions directly
- **AND** tests MUST NOT verify third-party library behavior as repository behavior

