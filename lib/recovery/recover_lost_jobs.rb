module Recovery
  class RecoverLostJobs
    def self.run
      RecoverLostJobsWorker.perform_async(ContentChange, ProcessContentChangeWorker)
      RecoverLostJobsWorker.perform_async(Message, ProcessMessageWorker)
    end
  end
end
