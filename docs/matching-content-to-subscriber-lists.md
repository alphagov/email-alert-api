# Matching content to subscriber lists

## Format of matching criteria

A subscriber list uses several fields to store the criteria which
define how it matches published content:

### JSON fields

- `links`
- `tags`

These fields contain a JSON object which maps keys to arrays of values,
similar to the links hash on a content item. For example:

```
{
    "key_1": {
        "any": ["value_a", "value_b", "value_c"],
    }
    "key_2": {
        "all": ["value_x", "value_y"]
    }
}
```

Only one of these should be used on a given subscriber list. They
can also both be empty `{}` if they aren't needed.

> You can find a list of permitted tags in [`lib/valid_tags.rb`](https://github.com/alphagov/email-alert-api/blob/3e0018510ea85f5d561e2865ad149832b94688a1/lib/valid_tags.rb).

For a published content item to match the subscriber list on these
fields, the links/tags in the request to email-alert-api must include
all of the keys. If the value includes `any` then at least one of the
values in the array needs to match for each key. If the value includes
`all`, then each value in the array needs to match.

`links` uses content ids and `tags` uses slugs - but the queries used
on these fields don't care about that difference.

It's crucial that the key names stored in these JSON fields match the
key names used in the requests to email-alert-api (which are usually
the same as the ones on the content item itself - [`taxon_tree` is an exception](https://github.com/alphagov/email-alert-service/pull/67)).
It's easy to break existing subscriptions by renaming a field in the
links hash on published content without updating the corresponding
subscriber lists, which would mean that subscribers stop getting emails
for that kind of content.

### String fields

- `document_type`
- `email_document_supertype`
- `government_document_supertype`

More than one of these can be used on a given subscriber list. The two
supertype fields were added to support the migration of Whitehall
subscriptions to email-alert-api.

These fields are used in addition to or instead of `links`/`tags` on a
given subscriber list. For example, a travel advice subscription for a
particular country uses `document_type` and `links -> countries`,
whereas the travel advice index subscription (which includes all
countries) only uses `document_type`. See [this wiki page](https://gov-uk.atlassian.net/wiki/pages/viewpage.action?pageId=108625932)
for details of how each kind of subscription works.

### UUID field

- `content_id`

This field stores the content ID of a page on GOV.UK.

Content ID based subscriber lists match against any content changes
that share the same content ID. These lists do not have populated
`document_type`, `email_document_supertype` or `government_document_supertype`
string fields.

Content ID based lists can also have links. When both links and content ID
are present, the list will match content changes by links OR by content-id.

This "OR" match means we can support reverse linked email subscriptions. For example:

A user subscribes to alerts on a document collection page, with content ID '123-abc'.
The params sent to email alert api contains both links and content ID, and will
create a subscriber list that contains:

```
content_id: "123-abc"
links: {
    "document_collections" : {
        "any"=> [ "123-abc" ]
    }
},

```
This list will match content changes made to the page with content ID "123-abc",
and it will also match content changes to child pages which are reverse linked to
to page with content id "123-abc".

## Finding matches

The queries on subscriber lists power the two sides of the email system:
subscribing and sending emails.

### Subscribing

When a user is subscribing to something, the frontend app handling the
email signup should use the
[API adapters `find_or_create_subscriber_list` method](https://github.com/alphagov/gds-api-adapters/blob/1ff0e2cd4ae019f0f79b1b640d54942b94dfeddb/lib/gds_api/email_alert_api.rb#L12).

This first makes a GET request to find an existing subscriber list to
use, and if one isn't found, it makes a POST request to create the
desired subscriber list in email-alert-api.

`GET /subscriber-lists?params...` searches the database for an existing
subscriber list which has exactly the same criteria as are given in the
query params. The order of keys and the items within the arrays in
`links` and `tags` doesn't matter.

### Sending emails

When a `POST /content-changes` request is made to email-alert-api, the
data in that request is used to find all subscriber lists in the
database which it matches. The matching criteria on each list act as
filters on the stream of published content: as long as the request
includes at least one matching value for every key in the matching
criteria on the subscriber list, an email will be sent to that list.
