require "lint/linter"

namespace :lint do
  desc "Lint the codebase"
  task :run do
    exit Linter.run
  end

  desc "Try to autofix lint errors"
  task :fix do
    exit Linter.fix
  end
end

task lint: "lint:run"
