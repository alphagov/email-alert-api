require "pathname"
ROOT = Pathname.new(File.expand_path(File.join(File.dirname(__FILE__), "..")))

$LOAD_PATH.push(ROOT)
$LOAD_PATH.push(ROOT.join("services"))
$LOAD_PATH.push(ROOT.join("repositories"))
$LOAD_PATH.push(ROOT.join("lib"))
$LOAD_PATH.push(ROOT.join("http"))
$LOAD_PATH.push(ROOT.join("persistence"))

GOVDELIVERY_CREDENTIALS = {
  username: "gov-delivery+staging@digital.cabinet-office.gov.uk",
  password: "nottherealpassword",
  account_code: "UKGOVUK",
  protocol: "https",
  hostname: "stage-api.govdelivery.com",
  subscription_link_template: "https://stage-public.govdelivery.com/accounts/UKGOVUK/subscriber/new?topic_id=%{topic_id}",
}

DB_URI = "postgres://localhost/email_alert_api_test?user=email_alert_api_user"
DB_MIGRATIONS_DIR = "persistence/postgres/migrations"
