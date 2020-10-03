module SetActiveLinkHelper
  # Just this works
  def activelink_class(name)
    controller_name.eql?(name) || current_page?(name) ? 'activelink' : ''
  end
end