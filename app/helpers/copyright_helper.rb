module CopyrightHelper
  #Footer Copyright
  def copyright_generator
    RodcodeViewTool::Renderer.copyright 'Website-Name | All rights reserved'
  end
end
