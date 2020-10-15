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

  # rescue_from 404 error
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
=begin
  rescue_from ActiveRecord::RecordNotFound do |exception|
    redirect_to root_path, 404, alert: I18n.t("errors.record_not_found")
  end
  # Or
  rescue_from ActiveRecord::RecordNotFound do |exception|
    redirect_to root_path, 404, alert: 'Record not found'
  end
=end

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
      flash[:danger] = t('review_login_alert')
    end
  end

  def is_admin?
    signed_in? ? current_user.admin : false
  end

  def set_locale
    begin
      if params[:locale] != nil
        cookies.permanent[:locale] = params[:locale]
      end
      I18n.locale = (user_signed_in? && current_user.try(:locale)) || cookies[:locale] || read_lang_header || "en"
    rescue I18n::InvalidLocale
      I18n.locale = "en"
    end
  end

  protected

    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :name, :email])
      devise_parameter_sanitizer.permit(:sign_in, keys: [:login])
      devise_parameter_sanitizer.permit(:account_update, keys: [:username, :name, :email, :avatar])
      devise_parameter_sanitizer.permit :accept_invitation, keys: [:username, :name, :email]
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

    # rescue_from 404 error
    def record_not_found
      render html: "Record <strong>not found</strong>", status: 404
    end

    def read_lang_header
      lang_header = request.env['HTTP_ACCEPT_LANGUAGE']
      lang_header.downcase.scan(/[a-z]{2}\-[a-z]{2}/).first unless lang_header.nil?
    end
end
