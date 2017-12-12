namespace :process do
  desc "Run the email generation service"
  task :email_generation_service, [] => :environment do
    EmailGenerationService.call
  end
end
