## Integration tests ##

The purpose of these tests is to check that units of email-alert-api work
together when combined into higher-level code. This ensures objects/classes
integrate together correctly.

These tests should:

- exercise code of more than one object/class

These tests should not:

- exhaustively test all code paths (save that for unit tests)
- know intimate details about implementation details of the components being tested
- e.g. stub out methods or assert that specific methods have been called

It is ok for these tests to:

- stub out methods of components not part of the integration test
- assert that calls have been made to components not part of the integration test

If you need to test an entire journey through the system, consider writing a
feature test instead. See `spec/features/README.md`.

If you need to test a single component exhaustively, consider writing a unit
test instead. See `spec/units/README.md`.
