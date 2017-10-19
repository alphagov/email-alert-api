module Linter
  class << self
    def run
      status = system("govuk-lint-ruby #{ENV['FILE']}")
      prompt_to_autofix unless status

      if rand < 0.5 && ENV["AUTOFIX"].nil?
        output("Top tip: You can set AUTOFIX=Y to skip the prompt", 36)
      elsif rand < 0.5 && ENV["FILE"].nil?
        output("Top tip: You can set FILE=some/file.rb to lint one file", 36)
      end

      exit status
    end

    def fix
      status = system("govuk-lint-ruby -a #{ENV['FILE']}")

      if status
        output("Woo, it worked :-)", 32)
      else
        output("Some lint errors couldn't be auto-fixed :-(", 31)
      end

      puts "\n\n"

      exit status
    end

  private

    def prompt_to_autofix
      return unless $stdout.isatty

      output("Should I try auto-fixing lint errors? (Y/n)", 33)
      puts ENV["AUTOFIX"]
      input = (ENV["AUTOFIX"] || STDIN.gets).strip.upcase

      fix if input.empty? || input == "Y"
    end

    def output(message, bash_color_code)
      puts "\n>>> \e[#{bash_color_code}m#{message}\e[0m"
    end
  end
end
