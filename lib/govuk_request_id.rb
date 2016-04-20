class GovukRequestId
  class << self
    def insert(body)
      return body unless body.present?

      if body =~ /^</
        body += govuk_request_id_html_comment
      end

      body
    end

  private

    def govuk_request_id_html_comment
      "\n<!-- govuk_request_id: #{govuk_request_id} -->\n"
    end

    def govuk_request_id
      GdsApi::GovukHeaders.headers[:govuk_request_id]
    end
  end
end
