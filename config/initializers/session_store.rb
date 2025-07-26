# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :cookie_store,
  key: '_mb_session',
  httponly: true,
  secure: Rails.env.production?,
  same_site: :lax,
  expire_after: 2.hours