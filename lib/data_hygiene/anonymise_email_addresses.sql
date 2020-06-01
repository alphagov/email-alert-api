-- This SQL file anonymises email addresses in the email-alert-api database.
--
-- It tries to preserve structure so that multiple occurences of the same address
-- are mapped to the same anonymous address.
--
-- It runs when we copy data to Integration via govuk_env_sync:
-- https://docs.publishing.service.gov.uk/manual/govuk-env-sync.html
--
-- Please make changes to this script in
-- https://github.com/alphagov/email-alert-api/blob/master/lib/data_hygiene/anonymise_email_addresses.sql
-- where it is tested. Then copy it to the govuk-puppet repository.

-- Deletes all emails that are older than 1 day old.

-- Deletion of emails is slow since email volumes have increased. We attempt to speed up the process
-- as discussed https://dba.stackexchange.com/questions/37034/very-slow-delete-in-postgresql-workaround
-- there are some disadvantages with doing that but we think it is fine to do for integration

ALTER TABLE emails DISABLE TRIGGER ALL;

-- Create a table to store old email addresses.
CREATE TABLE oldaddresses (uuid uuid PRIMARY KEY);

INSERT INTO oldaddresses(uuid)
(SELECT id FROM emails WHERE created_at >= current_timestamp - interval '1 day');

DELETE FROM emails
USING oldaddresses
WHERE emails.id = oldaddresses.uuid;

DELETE FROM subscription_contents
USING oldaddresses
WHERE subscription_contents.email_id = oldaddresses.uuid;

DELETE FROM delivery_attempts
USING oldaddresses
WHERE delivery_attempts.email_id = oldaddresses.uuid;

DROP TABLE oldaddresses;

ALTER TABLE emails ENABLE TRIGGER ALL;

-- Create a table to store all email addresses.
CREATE TABLE addresses (id SERIAL, address VARCHAR NOT NULL);

-- Copy all email addresses into the table.
-- Ignore nulled out subscriber addresses.
INSERT INTO addresses (address)
  SELECT address FROM subscribers WHERE address IS NOT NULL
  UNION DISTINCT
  SELECT address FROM emails;

-- Index the table so we can efficiently lookup addresses.
CREATE UNIQUE INDEX addresses_index ON addresses (address);

-- Set subscribers.address from the auto-incremented id in addresses table.
UPDATE subscribers s
SET address = CONCAT('anonymous-', a.id, '@example.com')
FROM addresses a
WHERE a.address = s.address;

-- Set emails.address from the auto-incremented id in addresses table.
UPDATE emails e
SET address = CONCAT('anonymous-', a.id, '@example.com'),
subject = REPLACE(e.subject, e.address, CONCAT('anonymous-', a.id, '@example.com')),
body = REPLACE(e.body, e.address, CONCAT('anonymous-', a.id, '@example.com'))
FROM addresses a
WHERE a.address = e.address;

-- Clean up by deleting the addresses table and its index.
DROP INDEX addresses_index;
DROP TABLE addresses;
