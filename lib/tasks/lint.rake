require "lint/linter"

namespace :lint do
  desc "Lint the codebase"
  task :run { exit Linter.run }

  desc "Try to autofix lint errors"
  task :fix { exit Linter.fix }
end

task lint: "lint:run"
