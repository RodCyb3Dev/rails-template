class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include Pagy::Backend
  include SetSource

  before_action :set_locale

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :masquerade_user!

  before_action :store_user_location!, if: :storable_location?
  # The callback which stores the current location must be added before you authenticate the user 
  # as `authenticate_user!` (or whatever your resource is) will halt the filter chain and redirect 
  # before the location can be stored.
  #before_action :authenticate_user!
  after_action :store_action

  def default_url_options
    { host: ENV["HOST_NAME"] || "localhost:3000" }
  end

  #To redirect to the stored location after the user signs in you would override the method with:
  def after_sign_in_path_for(resource_or_scope)
    stored_location_for(resource_or_scope) || super
  end

  def user_signed_in?
    !current_user.nil?
  end

  # Confirms a logged-in user.
  def logged_in_user
    unless user_signed_in?
        flash[:danger] = t('review_login_alert', :default => 'Sinulla ei ole valtuuksia suorittaa tätä toimintoa.')
    end
  end

  def is_admin?
    signed_in? ? current_user.admin : false
  end

  protected

    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :name])
      devise_parameter_sanitizer.permit(:account_update, keys: [:username, :name, :avatar])
      devise_parameter_sanitizer.permit :accept_invitation, keys: [:email]
    end

  private
    # Its important that the location is NOT stored if:
    # - The request method is not GET (non idempotent)
    # - The request is handled by a Devise controller such as Devise::SessionsController as that could cause an 
    #    infinite redirect loop.
    # - The request is an Ajax request as this can lead to very unexpected behaviour.
    def storable_location?
      request.get? && is_navigational_format? && !devise_controller? && !request.xhr? 
    end

    def store_user_location!
      store_location_for(:user, request.fullpath)
    end

    def store_action
      return unless request.get? 
      if (request.path != "/users/sign_in" &&
          request.path != "/users/sign_up" &&
          request.path != "/users/password/new" &&
          request.path != "/users/password/edit" &&
          request.path != "/users/confirmation" &&
          request.path != "/users/sign_out" &&
          request.path != "/users/auth/google_oauth2" &&
          !request.xhr?) # don't store ajax calls
        store_location_for(:user, request.fullpath)
      end
    end

    def set_locale
      I18n.locale = params[:locale] || I18n.default_locale
    end

    def default_url_options(options = {})
      {locale: I18n.locale}
    end

    def read_lang_header
      lang_header = request.env['HTTP_ACCEPT_LANGUAGE']
      lang_header.downcase.scan(/[a-z]{2}\-[a-z]{2}/).first unless lang_header.nil?
    end
end
