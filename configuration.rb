require "pathname"
ROOT = Pathname.new(File.dirname(__FILE__))

$LOAD_PATH.push(ROOT)
$LOAD_PATH.push(ROOT.join("services"))
$LOAD_PATH.push(ROOT.join("lib"))

GOVDELIVERY_USERNAME = 'gov-delivery+staging@digital.cabinet-office.gov.uk'
GOVDELIVERY_PASSWORD = 'nottherealpassword'
GOVDELIVERY_ACCOUNT_CODE = 'UKGOVUK'
GOVDELIVERY_HOSTNAME = 'stage-api.govdelivery.com'
GOVDELIVERY_SIGNUP_FORM = 'https://stage-public.govdelivery.com/accounts/UKGOVUK/subscriber/new?topic_id=%{topic_id}'

