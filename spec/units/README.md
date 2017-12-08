## Unit tests ##

The purpose of these tests is to check that single units of the system do the
right thing in isolation. This ensures individual units of the system behave
correctly, before they are combined with other things.

These tests should:

- be fairly exhaustive and cover the majority of code paths

These tests should not:

- know intimate details about implementation details of the unit being tested

It is ok for these tests to:

- stub out methods not part of the unit being tested
- assert that calls have been made to other units

If you need to test multiple units work together, consider writing an
integration test instead. See `spec/integration/README.md`.
