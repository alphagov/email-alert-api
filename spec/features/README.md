## Feature tests ##

The purpose of these tests is to check email-alert-api behaves correctly from
the perspective of someone using the API. This ensures we're testing the system
in a way representative of how someone will actually use it.

These tests should:

- interact with the api by calling its HTTP endpoints
- use the responses from these endpoints to make assertions about behaviour
- assert that calls have been made to external systems (e.g. Notify)

These tests should not:

- read/write directly from/to the database
- know intimate details about implementation details of the app
- e.g. stub out methods or assert that specific methods have been called

If you need to test smaller boundaries of the system, consider writing an
integration test instead. See `spec/integration/README.md`.
