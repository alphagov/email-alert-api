# Available endpoints

## Application

* `GET /subscriber-lists?tags[organisation]=cabinet-office` - gets a stored subscriber list that's relevant to just the `cabinet-office` organisation, in the form:

```json
{
  "subscriber_list": {
    "id": "an id",
    "title": "Title of topic",
    "subscription_url": "https://public-url/subscribe-here?topic_id=123",
    "gov_delivery_id": "123",
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

* `POST /subscriber-lists` with data:

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

and it will respond with the JSON response for the `GET` call above.

* `POST /content-changes` with data:

```json
{
  "subject": "This is the subject/title of my bulletin",
  "body": "Email body here",
  "tags": {
    "tag": ["values"]
  }
}
```

and it will respond with `202 Accepted` (the call is queued to prevent
slowness in the external notifications API).

The following fields are accepted on this endpoint: `subject`, `from_address_id`, `urgent`, `header`, `footer`,
`document_type`, `content_id`, `public_updated_at`, `publishing_app`, `email_document_supertype`,
`government_document_supertype`, `title`, `description`, `change_note`, `base_path`, `priority` and `footnote`.

* `POST /messages` with data:

```json
{
  "sender_message_id": "unique-identifier-for-each-message",
  "title": "This is the title of my bulletin",
  "url": "https://www.url.com",
  "body": "Email body here",
  "document_type": "",
  "email_document_supertype": "",
  "government_document_supertype": "",
  "priority": "weekly",
  "tags": {
    "tag": ["some-tag"]
  },
  "links": {
    "link": ["some-link"]
  }
}
```

and it will respond with `202 Accepted` (the call is queued).

* `POST /emails` with data:

```json
{
  "subject": "This is the subject/title of my bulletin",
  "body": "Email body here",
  "address": "recipient-email@address.com"
}

and it will respond with `202 Accepted` (the call is queued).

* `GET /subscribers/xxx/subscriptions` - gets a subscriber's subscriptions, in the form:

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

* `PATCH /subscribers/xxx` with data:

```json
{
  "new_address": "test2@example.com"
}
```

and it will respond with the details of the subscriber including the
new email address.

* `DELETE /subscribers/xxx` - unsubscribes a provided subscriber and returns `204 No Content`.

* `POST /subscriptions` with data:

```json
{
  "address": "email@address.com",
  "subscriber_list_id": "The id of a subscriber list"
}
```

and it will create a new subscription between the email address and the
subscriber list. It will respond with a `201 Created` if it's a new
subscription or a `200 OK` if the subscription already exists.

* `PATCH /subscriptions/xxxx` with data:

```json
{
  "frequency": "weekly"
}
```

and it will respond with the details of the subscription including the
new frequency.

* `POST /unsubscribe/xxx` - unsubscribes a subscriber from the provided subscription and returns `204 No Content`.

* `POST /subscribers/auth-token` with data:

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
