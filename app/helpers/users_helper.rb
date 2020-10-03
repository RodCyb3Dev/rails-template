module UsersHelper
  def admin?
    user_signed_in? && current_user.admin?
  end

  # Avatar
  def user_avatar(user, size=60)
    if user.avatar.attached?
      user.avatar.variant(resize: "#{size}x#{size}!")
    else
      gravatar_image_url(user.email, alt: user.first_name + '' + user.last_name, size: size)
    end
  end
end