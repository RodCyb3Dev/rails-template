module MetaHelper
  def default_meta_tags(options={})
    site_name   = Rails.configuration.application_name #t('meta.site_name')
    #title      = [controller_name, action_name].join(" ")
    title       = @page_title
    description = t('meta.description')
    image       = options[:image] || "https://res.cloudinary.com/dwougdhor/image/asset/c_scale,w_32/v1563807309/favicon-f0420b43dd46d60f6d39873134b0cfe2.png"
    current_url = request.url

    # Let's prepare a nice set of defaults
    defaults = {
      site:        site_name,
      title:       title,
      image:       image,
      description: description,
      keywords:    t('meta.keywords'),
      twitter: {
        site_name: site_name,
        site: '@rodney_hammad', #replace with your username
        card: 'summary',
        description: description,
        image: image
      },
      og: {
        url: current_url,
        site_name: site_name,
        title: title,
        image: image,
        description: description,
        type: 'website'
      }
    }

    options.reverse_merge!(defaults)

    set_meta_tags options
  end
end