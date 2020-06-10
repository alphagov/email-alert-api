Email Alert API Field Reference
===============================

## Subscriber Lists

Subscriber Lists in Email Alert API can have tags or links. When a document is
is changed, the API does a search for the document's attributes in the API to
find a matching subscriber list.

### Tags

The API has a whitelist of available tags that a user can subscribe to.

You can find a list of permitted tags in [`lib/valid_tags.rb`](https://github.com/alphagov/email-alert-api/blob/3e0018510ea85f5d561e2865ad149832b94688a1/lib/valid_tags.rb).
