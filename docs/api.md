# Available endpoints

## Application

### `GET /subscriber-lists?tags[organisation]=cabinet-office`

Gets a stored subscriber list that's relevant to just the `cabinet-office` organisation, in the form:

```json
{
  "subscriber_list": {
    "id": "an id",
    "title": "Title of topic",
    "subscription_url": "https://public-url/subscribe-here?topic_id=123",
    "gov_delivery_id": "123",
    "group_id": "f513e107-b2c6-44a6-8d8a-9e6a3ea37b9d",
    "document_type": "",
    "created_at": "20141010T12:00:00",
    "updated_at": "20141010T12:00:00",
    "tags": {
      "any": {
        "topics": ["topic-slug"],
      }
    }
  }
}
```

### `POST /subscriber-lists`

```json
{
  "title": "My title",
  "group_id": "f513e107-b2c6-44a6-8d8a-9e6a3ea37b9d",
  "tags": {
    "any": {
      "organisations": ["my-org"],
    }
  }
}
```

It will respond with the JSON response for the `GET` call above.

The following fields are accepted:

- title: The title of this particular list, which will be shown to the user;
- description: Markdown text that will be used as copy in the confirmation
  email sent to a user;
- url: A url to a page that reflects what the user signed up to and can be
  linked to with their list;
- group_id: A UUID that can be provided by an application to group together
  lists for the same resource with different criteria;
- links: An object where keys are a link type and the value is an object
  containing a key of "any" or "all" associated with an array of link values,
  this is used to match content changes and messages to the list;
- tags: An object where keys are [valid tags][] and the value is an object
  containing a key of "any" or "all" associated with an array of link values
  this is used to match content changes and messages to the list;
- document_type: A field that can be used to match with content changes that
  share the corresponding field;
- email_document_supertype: A field that can be used to match with content
  changes that share the corresponding field;
- government_document_supertype: A field that can be used to match with
  content changes that share the corresponding field.

[valid tags]: https://github.com/alphagov/email-alert-api/blob/b6428880aa730e316803d7129db3ec47304e933b/lib/valid_tags.rb

### `POST /content-changes`

```json
{
  "subject": "This is the subject/title of my bulletin",
  "body": "Email body here",
  "tags": {
    "tag": {
      "any": ["values"]
    }
  }
}
```

It will respond with `202 Accepted` (the call is queued to prevent
slowness in the external notifications API).

The following fields are accepted on this endpoint: `subject`, `from_address_id`, `urgent`, `header`, `footer`,
`document_type`, `content_id`, `public_updated_at`, `publishing_app`, `email_document_supertype`,
`government_document_supertype`, `title`, `description`, `change_note`, `base_path`, `priority` and `footnote`.

### `POST /messages`

```json
{
  "sender_message_id": "4da7a6a7-c8f7-482e-aeb9-a26cea90780c",
  "title": "Message title",
  "url": "/path-to-a-govuk-page",
  "body": "Message body",
  "criteria_rules": [
    { "type": "tag", "key": "tag-name", "value": "tag-value" }
  ]
}
```

It will respond with `202 Accepted` (the call is queued).

The following fields are accepted on this endpoint: `sender_message_id`,
`title`, `url`, `body`, `criteria_rules`, and `priority`.

### `POST /emails`

```json
{
  "subject": "This is the subject/title of my bulletin",
  "body": "Email body here",
  "address": "recipient-email@address.com"
}
```

It will respond with `202 Accepted` (the call is queued).

### `GET /subscribers/xxx/subscriptions`

Gets a subscriber's subscriptions, in the form:

```json
{
  "subscriber": {
    "id": 1,
    "address": "test@example.com",
    "created_at": "Wed, 07 Mar 2018 17:04:28 UTC +00:00",
    "updated_at": "Wed, 07 Mar 2018 17:04:28 UTC +00:00",
    "signon_user_uid": null,
    "deactivated_at": null
  },
  "subscriptions": [
    {
      "subscriber_id": 1,
      "subscriber_list_id": 4232,
      "created_at": "Wed, 07 Mar 2018 18:52:25 UTC +00:00",
      "updated_at": "Wed, 07 Mar 2018 18:52:25 UTC +00:00",
      "frequency": "daily",
      "signon_user_uid": null,
      "id": "476e1439-f5ba-4d7a-b4aa-1090563c5c36",
      "source": "imported",
      "ended_at": null,
      "ended_reason": null,
      "subscriber_list": {
        "id": 4232,
        "title": "All types of document about all topics by Foreign & Commonwealth Office",
        "created_at": "Thu, 01 Aug 2013 12:53:34 UTC +00:00",
        "updated_at": "Tue, 13 Mar 2018 15:11:29 UTC +00:00",
        "document_type": "",
        "tags": {},
        "links": {
          "organisations": ["9adfc4ed-9f6c-4976-a6d8-18d34356367c"]
        },
        "email_document_supertype": "",
        "government_document_supertype": "",
        "signon_user_uid": null,
        "slug": "all-types-of-document-about-all-topics-by-foreign-commonwealth-office"
      }
    }
  ]
}
```

### `PATCH /subscribers/xxx`

```json
{
  "new_address": "test2@example.com"
}
```

It will respond with the details of the subscriber including the
new email address.

* `DELETE /subscribers/xxx` - unsubscribes a provided subscriber and returns `204 No Content`.

* `POST /subscriptions` with data:

```json
{
  "address": "email@address.com",
  "subscriber_list_id": "The id of a subscriber list",
  "frequency": "weekly"
}
```

It will create a new subscription between the email address and the
subscriber list. It will respond with a `201 Created` if it's a new
subscription or a `200 OK` if the subscription already exists. If a
subscription already exists but the frequency is different, the
current subscription is ended and a new one with the updated frequency
is created. A confirmation email will be sent if a new subscription is
created or if the subscriber is reactivated and the subscription already
exists.

> Note: using any email address that ends with `@notifications.service.gov.uk`
will not create a subscriber or a subscription, however will return a `201 Created` response.

### `PATCH /subscriptions/xxxx`

```json
{
  "frequency": "weekly"
}
```

It will respond with the details of the subscription including the
new frequency.

### `POST /unsubscribe/xxx`

Unsubscribes a subscriber from the provided subscription and returns `204 No Content`.

### `POST /subscribers/auth-token`

```json
{
  "address": "test@example.com",
  "destination": "/authentication-page-on-govuk",
  "redirect": "/page-user-wanted-on-govuk",
}
```

This will trigger an email to the address specified with a link to the
destination with a query string of token and a [JWT](https://jwt.io/) token.
Returns a 201 status code on success or 404 if the subscriber is not known
to Email Alert API.

## Healthcheck

A queue health check endpoint is available at `/healthcheck`.

```json
{
  "checks": {
    "queue_size": {
      "status": "ok"
    },
    "queue_age": {
      "status": "ok"
    }
  },
  "status": "ok"
 }
```
