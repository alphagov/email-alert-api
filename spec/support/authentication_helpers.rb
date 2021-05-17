module AuthenticationHelpers
  def login_with_internal_app
    login_with("internal_app")
  end

  def login_with_signin
    login_with("signin")
  end

  def login_with_status_updates
    login_with("status_updates")
  end

  def login_with(permissions)
    login_as(create(:user, permissions: Array(permissions)))
  end

  def without_login(&block)
    ClimateControl.modify(GDS_SSO_MOCK_INVALID: "1", &block)
  end

  def login_as(user)
    GDS::SSO.test_user = user
  end

  def logout
    GDS::SSO.test_user = nil
  end
end
