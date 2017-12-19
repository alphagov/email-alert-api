# This SQL file anonymises email addresses in the email-alert-api database.
#
# It tries to preserve structure so that multiple occurences of the same address
# are mapped to the same anonymous address.
#
# It runs when we copy data to integration:
# https://deploy.publishing.service.gov.uk/job/Copy_Data_to_Integration/
#
# Please make changes to this script in email-alert-api where it is tested.
# Then copy it to the env-sync-and-backup repository.

# Create a table to store all email addresses.
CREATE TABLE addresses (id SERIAL, address VARCHAR NOT NULL);

# Copy all email addresses into the table.
INSERT INTO addresses (address)
  SELECT address FROM subscribers
  UNION DISTINCT
  SELECT address FROM emails;

# Index the table so we can efficiently lookup addresses.
CREATE UNIQUE INDEX addresses_index ON addresses (lower(address));

# Set subscribers.address from the auto-incremented id in addresses table.
UPDATE subscribers s
SET address = CONCAT('anonymous-', a.id, '@example.com')
FROM addresses a
WHERE a.address = s.address;

# Set emails.address from the auto-incremented id in addresses table.
UPDATE emails e
SET address = CONCAT('anonymous-', a.id, '@example.com')
FROM addresses a
WHERE a.address = e.address;

# Clean up by deleting the addresses table and its index.
DROP INDEX addresses_index;
DROP TABLE addresses;
