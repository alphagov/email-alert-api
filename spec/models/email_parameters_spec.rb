RSpec.describe EmailParameters do
  describe "#add_query_params" do
    let(:redirect) {
      double(:redirect, path: '/somewhere', title: 'redirect_title', url: 'https://redirect.to/somewhere')
    }

    it 'adds empty no query parameters' do
      params = EmailParameters.new(
        subject: '',
        address: '',
        redirect: double(:redirect,
                         path: '',
                         title: '',
                         url: 'https://redirect.to/somewhere'),
        utm_parameters: {},
        subscriber_id: nil
      )
      expect(params.add_utm(params.redirect.url)).to eq('https://redirect.to/somewhere?')
    end

    it 'adds query parameters' do
      params = EmailParameters.new(
        subject: '',
        address: '',
        redirect: double(:redirect,
                         path: '',
                         title: '',
                         url: 'https://redirect.to/somewhere'),
        utm_parameters: { a: 3, b: 4 },
        subscriber_id: nil
      )
      expect(params.add_utm(params.redirect.url)).to eq('https://redirect.to/somewhere?a=3&b=4')
    end
    it 'adds query parameters when there are existing query parameters' do
      params = EmailParameters.new(
        subject: '',
        address: '',
        redirect: double(:redirect,
                         path: '',
                         title: '',
                         url: 'https://redirect.to/somewhere?c=1'),
        utm_parameters: { a: 3, b: 4 },
        subscriber_id: nil
      )
      expect(params.add_utm(params.redirect.url)).to eq('https://redirect.to/somewhere?c=1&a=3&b=4')
    end
  end
end
