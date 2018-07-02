RSpec::Matchers.define :gzipped_match do |regex|
  match do |contents|
    decrypted = ActiveSupport::Gzip.decompress(contents)
    decrypted.match(regex)
  end
end
