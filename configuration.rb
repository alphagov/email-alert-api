require "pathname"
ROOT = Pathname.new(File.dirname(__FILE__))

$LOAD_PATH.push(ROOT)
$LOAD_PATH.push(ROOT.join("services"))
$LOAD_PATH.push(ROOT.join("lib"))
$LOAD_PATH.push(ROOT.join("http"))

GOVDELIVERY_CREDENTIALS = {
  username: "gov-delivery+staging@digital.cabinet-office.gov.uk",
  password: "nottherealpassword",
  account_code: "UKGOVUK",
  protocol: "https",
  hostname: "stage-api.govdelivery.com",
  signup_form: "https://stage-public.govdelivery.com/accounts/UKGOVUK/subscriber/new?topic_id=%{topic_id}",
}
