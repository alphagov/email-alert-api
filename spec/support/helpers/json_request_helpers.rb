module JSONRequestHelpers
  def json_headers
    {
      'CONTENT_TYPE' => "application/json",
      'ACCEPT' => 'application/json'
    }
  end
end
