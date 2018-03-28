class EmailAddressValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if !value.nil? && !valid_email_address?(value)
      record.errors.add(attribute, 'is not an email address')
    end
  end

private

  def valid_email_address?(email_address)
    contains_one_at_sign?(email_address) &&
      contains_a_valid_domain?(email_address) &&
      is_a_single_email_address?(email_address) &&
      does_not_contain_whitespace?(email_address)
  end

  def contains_one_at_sign?(email_address)
    email_address.scan('@').length == 1
  end

  def contains_a_valid_domain?(email_address)
    domain = email_address.split('@')[1]
    return false if domain.nil?
    domain_contains_at_least_one_dot?(domain) ||
      domain_is_an_ip_address?(domain)
  end

  def is_a_single_email_address?(email_address)
    email_address.scan(',').empty?
  end

  def does_not_contain_whitespace?(email_address)
    email_address !~ /\s/
  end

  def domain_contains_at_least_one_dot?(domain)
    !domain.start_with?('.') && !domain.scan('.').empty?
  end

  def domain_is_an_ip_address?(domain)
    domain.start_with?('[') && domain.end_with?(']')
  end
end
