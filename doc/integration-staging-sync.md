# Integration & Staging Sync

## Overview

Every morning the data in our integration and staging databases is synchronised
with production. We also need to keep GovDelivery in sync so that the
GovDelivery Topic IDs that we hold in our database continue to link to the
correct topics in every environment.

This is complicated by the fact that both integration and staging talk to the
same staging 'instance' of GovDelivery. Despite being separate accounts, the
GovDelivery topic ids have to be unique across the entire instance.

To achieve the synchronisation we have a rake task
(`sync_govdelivery_topic_mappings`) which is automatically triggered when the
'Data Sync Complete' job runs in Jenkins on [integration](https://deploy.integra
tion.publishing.service.gov.uk/job/Data_Sync_Complete/) and [staging](https://de
ploy.staging.publishing.service.gov.uk/job/Data_Sync_Complete/).

This rake task does three things:

1) Update the subscriber lists in our database to ensure the prefix for all of
the topics matches the account id. This only has an effect in integration, where
it changes all topics from UKGOVUK_XXXXX to UKGOVUKDUP_XXXXX.

2) Get a list of all topics currently in GovDelivery and delete them.

3) Recreate all of the topics in our subscriber lists, specifying both the title
of the topic and its topic id.

Sometimes the task does not run correctly – for example it may fail to find any
existing topics and delete them. If this happens, it may then create the new
topics with completely different topic IDs, ignoring the IDs being specified.
Surprise!

The rake task is safe to re-run at any time, but it does take a while to
complete.

New topics that are created within an environment (e.g. when testing with new
email signups in integration) will use the correct account id prefix for their
environment and should 'just work'*.

\* Famous last words.
