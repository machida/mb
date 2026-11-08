class Admin::CsrfTokensController < Admin::BaseController
  # Return a fresh token for the current authenticated session, never a cached one.
  def show
    response.headers["Cache-Control"] = "no-store"
    render json: { token: form_authenticity_token }
  end
end
