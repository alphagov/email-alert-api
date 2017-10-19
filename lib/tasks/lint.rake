require "lint/linter"

namespace :lint do
  desc "Lint the codebase"
  task :run { Linter.run }

  desc "Try to autofix lint errors"
  task :fix { Linter.fix }
end

task lint: "lint:run"
