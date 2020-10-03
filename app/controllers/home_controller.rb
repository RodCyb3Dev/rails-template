class HomeController < ApplicationController
  # Home
  def index
    @page_title = t('home_page')
  end

  # About
  def about
    @page_title = t('about_page')
  end

  def terms
    @page_title = t('terms_link')
  end

  def privacy
    @page_title = t('privacy_link')
  end
end