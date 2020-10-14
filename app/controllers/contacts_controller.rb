class ContactsController < ApplicationController
  #content_security_policy do |policy|
  #  content_security_policy_report_only only: :new
  #end
  
  def new
    @contact = Contact.new
    @page_title = t('contact_page')
  end

  def create
    @contact = Contact.new(contact_params)

    if @contact.valid?
      ContactMailer.contact_me(@contact).deliver_now
      redirect_to root_url, notice: t('contact_sent_msg')
    else
      redirect_to new_contact_url, notice: t('contact_filled_msg')
      render :new
    end
  end

  private

  def contact_params
    params.require(:contact).permit(:name, :email, :subject, :body, :nickname)
  end
end
