# Available endpoints

## Application

### `GET /subscriber-lists?tags[organisation]=cabinet-office`

Gets a stored subscriber list that's relevant to just the `cabinet-office` organisation, in the form:

```json
{
  "subscriber_list": {
    "id": "an id",
    "title": "Title of topic",
    "gov_delivery_id": "123",
    "document_type": "",
    "content_id": "",
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
  email sent to a user;
- url: A url to a page that reflects what the user signed up to and can be
  linked to with their list;
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
- content_id: A field that can be used to match with a single content item
  for subscriptions to individual pages or pieces of guidance.

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
  "body": "Message body",
  "criteria_rules": [
    { "type": "tag", "key": "tag-name", "value": "tag-value" }
  ]
}
```

It will respond with `202 Accepted` (the call is queued).

The following fields are accepted on this endpoint: `sender_message_id`,
`title`, `url`, `body`, `criteria_rules`, and `priority`.

### `GET /subscribers/xxx/subscriptions`

Gets a subscriber's subscriptions, in the form:

```json
{
  "subscriber": {
    "id": 1,
    "address": "test@example.com",
    "created_at": "Wed, 07 Mar 2018 17:04:28 UTC +00:00",
    "updated_at": "Wed, 07 Mar 2018 17:04:28 UTC +00:00",
    "signon_user_uid": null
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
        "content_id": "",
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
  "skip_confirmation_email": true (optional)
}
```

It will create a new subscription between the email address and the subscriber
list. If a subscription already exists but the frequency is different, the
current subscription is ended and a new one with the updated frequency is created.
It will respond with the details of the subscription.

A confirmation email will be sent unless the "skip_confirmation_email" flag is
set (e.g. if the calling app is going to send it's own confirmation email).

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
destination with a query string of token and a [JWT](https://jwt.io/)
token.  Returns a 201 status code on success; a 403 status code if the
subscriber is linked to a GOV.UK Account; or a 404 status code if the
subscriber is not known to Email Alert API.

### `POST /subscribers/govuk-account`

```json
{
  "govuk_account_session": "session-token-from-account-header"
}
```

Checks if the given GOV.UK account has a verified email address which
matches a subscriber and, if so, returns the subscriber in the form

```json
{
  "subscriber": {
    "id": 1,
    "address": "test@example.com",
    "created_at": "Wed, 07 Mar 2018 17:04:28 UTC +00:00",
    "updated_at": "Wed, 07 Mar 2018 17:04:28 UTC +00:00",
  }
}
```

Returns a 401 if the account session identifier is invalid.

Returns a 403 if the account's email address is not verified.

The 403 and 200 responses may optionally have a
`govuk_account_session` response field, which should replace the value
in the user's session.

### `POST /subscribers/govuk-account/link`

```json
{
  "govuk_account_session": "session-token-from-account-header"
}
```

Looks up a GOV.UK Account and finds or creates a subscriber (in the
same way as `POST /subscribers/govuk-account`), and stores the GOV.UK
Account ID against the subscriber record.  Returns the subscriber in
the form:

```json
{
  "subscriber": {
    "id": 1,
    "govuk_account_id": "user-id",
    "address": "test@example.com",
    "created_at": "Wed, 07 Mar 2018 17:04:28 UTC +00:00",
    "updated_at": "Wed, 07 Mar 2018 17:04:28 UTC +00:00",
  }
}
```

If the subscriber was not previously linked to a GOV.UK account, they
are sent an email listing the active subscriptions which they can now
manage through their account.  If they had no active subscriptions, no
email is sent.

Returns a 401 if the account session identifier is invalid.

Returns a 403 if the account's email address is not verified.

The 403 and 200 responses may optionally have a
`govuk_account_session` response field, which should replace the value
in the user's session.

### `GET /subscribers/govuk-account/:id`

Looks for a subscriber with a matching GOV.UK Account ID (as
previously set by `POST /subscribers/govuk-account/link`) and, if
there is one, returns it in the form:

```json
{
  "subscriber": {
    "id": 1,
    "govuk_account_id": "user-id",
    "address": "test@example.com",
    "created_at": "Wed, 07 Mar 2018 17:04:28 UTC +00:00",
    "updated_at": "Wed, 07 Mar 2018 17:04:28 UTC +00:00",
  }
}
```

Returns a 404 if there is no matching subscriber.

### `POST /unpublication_notification`

Looks up a subscription list by content ID. If there are subscribers
notify them the item they were subscribed to has been unpublished and remove their subscription.

Optionally pass a notification_template parameter to customise the
notification to users, providing more information about the type
of unpublication (for example publishing in error)

```json
{
  "content_id": "4da7a6a7-c8f7-482e-aeb9-a26cea90780c",
  "notification_template": "default"
}
```

Allowed notification types are:
- "default" - Generic unsubscription notification with no further details

Returns a 202 if the request is accepted, and emails are queued.

Returns a 400 if the notification_template does not match any
known templates.

Returns a 404 if the content_id cannot be matched to any subscription_list.

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
