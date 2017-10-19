desc "Run govuk-lint-ruby"
task :lint do
  exit system("govuk-lint-ruby")
end
