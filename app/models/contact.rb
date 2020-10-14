class Contact #< ApplicationRecord
  include ActiveModel::Model
  attr_accessor :name, :email, :subject, :body, :nickname
  validates :name, :email, :subject, :body, presence: true
end
