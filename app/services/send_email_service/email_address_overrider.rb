class SendEmailService::EmailAddressOverrider
  attr_reader :override_address, :whitelist_addresses, :whitelist_only

  def initialize(config)
    @override_address = config[:email_address_override]
    @whitelist_addresses = Array(config[:email_address_override_whitelist])
    @whitelist_only = config[:email_address_override_whitelist_only]
  end

  def destination_address(address)
    return address unless override_address

    if whitelist_addresses.include?(address)
      address
    else
      whitelist_only ? nil : override_address
    end
  end
end
