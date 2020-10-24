class HomeController < ApplicationController
  # Home
  def index
    @posts = Post.where("created_at >= ?", 8.months.ago.utc).order("created_at DESC").limit(3) #Show only three Posts here.
    @contact = Contact.new #this allows use to show contact form.

    # Meta Tags & dynamic page title
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

  def download
    send_file 'public/somefile_1.pdf', :type => "application/pdf", :filename => "somefile_1.pdf", status: 202
  end
  def download2
    send_file 'public/somefile_2.pdf', :type => "application/pdf", :filename => "somefile_2.pdf", status: 202
  end
end