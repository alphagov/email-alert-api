namespace :lint do
  def output(message, bash_color_code)
    puts "\n>>> \e[#{bash_color_code}m#{message}\e[0m"
  end

  task :run do
    status = system("govuk-lint-ruby #{ENV["FILE"]}")
    Rake::Task["lint:prompt"].execute unless status

    if rand < 0.5 && ENV["AUTOFIX"].nil?
      output("Top tip: You can set AUTOFIX=Y to skip the prompt", 36)
    elsif rand < 0.5 && ENV["FILE"].nil?
      output("Top tip: You can set FILE=some/file.rb to lint one file", 36)
    end

    exit status
  end

  task :prompt do
    return unless $stdout.isatty

    output("Should I try auto-fixing lint errors? (Y/n)", 33)
    puts ENV["AUTOFIX"]
    input = (ENV["AUTOFIX"] || STDIN.gets).strip.upcase

    Rake::Task["lint:fix"].execute if input.empty? || input == "Y"
  end

  task :fix do
    status = system("govuk-lint-ruby -a #{ENV["FILE"]}")

    if status
      output("Woo, it worked :-)", 32)
    else
      output("Some lint errors couldn't be auto-fixed :-(", 31)
    end

    puts "\n\n"

    exit status
  end
end

task lint: "lint:run"
