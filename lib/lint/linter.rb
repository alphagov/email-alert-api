module Linter
  class << self
    def run
      status = system("govuk-lint-ruby")
      status = prompt_to_autofix if !status && $stdout.isatty
      status
    end

    def fix
      status = system("govuk-lint-ruby -a")

      if status
        output("Woo, it worked :-)", 32)
      else
        output("Some lint errors couldn't be auto-fixed :-(", 31)
      end

      status
    end

  private

    def prompt_to_autofix
      output("Should I try auto-fixing lint errors? (Y/n)", 33)
      input = STDIN.gets.strip.upcase

      fix if input.empty? || input == "Y"
    end

    def output(message, bash_color_code)
      puts "\n>>> \e[#{bash_color_code}m#{message}\e[0m"
    end
  end
end
