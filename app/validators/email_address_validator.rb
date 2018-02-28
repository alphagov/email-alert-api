class EmailAddressValidator < ActiveModel::Validator
  def validate(record)
    email_address = record.address
    unless email_address.nil? || valid_email_address?(email_address)
      record.errors.add(:address, 'is not an email address')
    end
  end

private

  def valid_email_address?(email_address)
    contains_one_at_sign?(email_address) &&
      contains_a_valid_domain?(email_address) &&
      is_a_single_email_address?(email_address) &&
      does_not_contain_newline_characters?(email_address)
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

  def does_not_contain_newline_characters?(email_address)
    email_address !~ /\n/
  end

  def domain_contains_at_least_one_dot?(domain)
    !domain.start_with?('.') && !domain.scan('.').empty?
  end

  def domain_is_an_ip_address?(domain)
    domain.start_with?('[') && domain.end_with?(']')
  end
end
