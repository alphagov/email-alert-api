require "pathname"
ROOT = Pathname.new(File.expand_path(File.join(File.dirname(__FILE__), "..")))

$LOAD_PATH.push(ROOT)
$LOAD_PATH.push(ROOT.join("services"))
$LOAD_PATH.push(ROOT.join("repositories"))
$LOAD_PATH.push(ROOT.join("lib"))
$LOAD_PATH.push(ROOT.join("http"))
$LOAD_PATH.push(ROOT.join("persistence"))
$LOAD_PATH.push(ROOT.join("validators"))
$LOAD_PATH.push(ROOT.join("entities"))

require "config_loader"
CONFIG = ConfigLoader.new(Dir.glob("config/*.yml"))
