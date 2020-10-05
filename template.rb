require "fileutils"
require "shellwords"

=begin
Template Name: Kodeflash application template - Tailwind CSS
Author: Rodney H
Author URI: https://kodeflash.com
Instructions: $ rails new myapp -d <postgresql, mysql, sqlite> -m template.rb
=end
def add_template_repository_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    require "tmpdir"
    source_paths.unshift(tempdir = Dir.mktmpdir("kodeflash-Rails-template-"))
    at_exit { FileUtils.remove_entry(tempdir) }
    git clone: [
      "--quiet",
      "https://raw.githubusercontent.com/Rodcode47/kodeflash-Rails-template/master/template.rb",
      tempdir
    ].map(&:shellescape).join(" ")


    if (branch = __FILE__[%r{kodeflash-Rails-template/(.+)/template.rb}, 1])
      Dir.chdir(tempdir) { git checkout: branch }
    end
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

def rails_version
  @rails_version ||= Gem::Version.new(Rails::VERSION::STRING)
end

def rails_5?
  Gem::Requirement.new(">= 5.2.0", "< 6.0.0").satisfied_by? rails_version
end

def rails_6?
  Gem::Requirement.new(">= 6.0.0", "< 7").satisfied_by? rails_version
end

def add_gems
  # ADMIN
  gem 'rails_admin', '~> 2.0'
  gem 'rails_admin_rollincode', '~> 1.3'
  gem 'rails_admin-i18n'

  gem 'devise', '~> 4.7', '>= 4.7.1'
  gem 'devise_invitable'
  gem 'devise_masquerade', '~> 1.2'
  gem 'devise-i18n', '~> 1.9'
  gem 'devise-tailwindcssed', '~> 0.1.3'
  gem "pundit"
  gem 'font-awesome-sass', '~> 5.6', '>= 5.6.1'
  gem 'gravatar_image_tag', github: 'mdeering/gravatar_image_tag'
  gem 'mini_magick', '~> 4.9', '>= 4.9.2'
  gem 'name_of_person', '~> 1.1'
  gem 'omniauth-facebook', '~> 5.0'
  gem 'omniauth-github', '~> 1.3'
  gem 'omniauth-twitter', '~> 1.4'
  gem 'omniauth-linkedin-oauth2', '~> 1.0'
  gem 'omniauth-google-oauth2', '~> 0.8.0'
  gem 'sidekiq', '~> 6.0', '>= 6.0.3'
  gem 'sitemap_generator', '~> 6.0', '>= 6.0.1'
  gem 'whenever', require: false
  gem 'friendly_id', '~> 5.3'
  gem 'rodcode_view_tool', git: 'https://github.com/Rodcode47/my-ruby-gems'
  gem 'uglifier', '>= 1.3.0'
  gem 'sassc-rails', '~> 2.1', '>= 2.1.2'
  gem 'pagy', '~> 3.7', '>= 3.7.1'
  gem 'cookies_eu', '~> 1.7', '>= 1.7.6'
  gem 'uglifier', '>= 1.3.0'
  ### Delivering static images through a CDN
  gem 'rack-cors', '~> 1.0', '>= 1.0.3'
  gem 'meta-tags'
  gem "lazyload-rails"
  #gem 'pdfjs_viewer-rails', '~> 0.3.1'
  # locale data and translations to internationalize
  gem 'i18n'
  gem 'rails-i18n'

  gem_group :development, :test do
    gem 'dotenv-rails'
    gem 'letter_opener_web'
    gem "better_errors"
    gem 'pry-byebug'
    gem 'pry-rails'
  end

  if rails_5?
    gsub_file "Gemfile", /gem 'sqlite3'/, "gem 'sqlite3', '~> 1.3.0'"
    gem 'webpacker', '~> 4.0.1'
  end
end

# Database
database_config = "defaults: &defaults
  adapter: postgresql
  encoding: unicode
  username: postgres
  password:
  pool: <%= ENV.fetch('RAILS_MAX_THREADS') { 5 } %>
development:
  <<: *defaults
  database: #{app_name}_development
test:
  <<: *defaults
  database: #{app_name}_test
production:
  <<: *defaults
  url: <%= ENV['DATABASE_URL'] %>
  #database: #{app_name}_production
  #username: #{app_name}
  #password: #{app_name}"

remove_file "config/database.yml"
create_file "config/database.yml", database_config


def set_application_name
  # Add Application Name to Config
  if rails_5?
    environment "config.application_name = Rails.application.class.parent_name"
  else
    environment "config.application_name = Rails.application.class.module_parent_name"
  end

  # Announce the user where he can change the application name in the future.
  puts "You can change application name inside: ./config/application.rb"
end

# set config/application.rb
application do <<-EOF
    # Set timezone
    #config.time_zone = 'Helsinki'
    #config.active_record.default_timezone = :local

    # Set locale
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    config.i18n.available_locales = [:fi, :en]
    config.i18n.default_locale = :en
    I18n.enforce_available_locales = true
  EOF
end

def add_users
  # Install Devise
  generate "devise:install"

  # Devise notices are installed via Bootstrap
  #generate "devise:views:bootstrapped"
  #generate "devise:i18n:views"
  # Tailwind views generator 
  #generate devise:views:tailwindcssed

  # install Devise locales
  remove_file 'config/locales/devise.en.yml'
  generate "devise:i18n:locale en"
  #generate "devise:i18n:locale fi"

  # Create Devise User
  generate :devise, "User",
           "username",
           "first_name",
           "last_name",
           "admin:boolean",
           "role:integer"

  # Set admin default to false
  in_root do
    migration = Dir.glob("db/migrate/*").max_by{ |f| File.mtime(f) }
    gsub_file migration, /:admin/, ":admin, :default => false"
  end

  if Gem::Requirement.new("> 5.2").satisfied_by? rails_version
    gsub_file "config/initializers/devise.rb",
      /  # config.secret_key = .+/,
      "  config.secret_key = Rails.application.credentials.secret_key_base"
  end

  # Add Devise masqueradable to users
  inject_into_file("app/models/user.rb", "omniauthable, :masqueradable, :confirmable, 
          :lockable, :timeoutable, :", after: "devise :")
  inject_into_file("app/models/user.rb", ", omniauth_providers: [:linkedin, :twitter, :github, :google_oauth2]", after: ":validatable")

  inject_into_file 'app/models/user.rb', before: 'end' do
    "\n extend FriendlyId
        friendly_id :uniqueslug, use: :slugged 

        enum role: [:user, :admin, :vip] # You can call your roles whatever you want. User will be 1, Admin will be 2, and VIP will be 3.
        after_initialize :set_default_role, :if => :new_record?

        def set_default_role
          self.role ||= :user
        end

        has_person_name
        validates_presence_of :name

        has_one_attached :avatar

        # For friendly_id use
        def uniqueslug
          # Add here
        end

        # Add validations for the first and last name length
        validates :first_name, presence: true,
        length: { minimum: 2, maximum: 25 }

        validates :last_name, presence: true,
        length: { minimum: 2, maximum: 25 }

        # Now let’s add some password requirements:
        validate :password_complexity

        def password_complexity
          if password.present? and not password.match(/\A(?=.{8,})(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[[:^alnum:]])/)
            errors.add :password, 'must include at least one lowercase letter, one uppercase letter, and one digit.'
          end
        end

        def avatar_url
          hash = Digest::MD5.hexdigest(email)
          'http://www.gravatar.com/avatar/#{hash}'
        end\n"
  end

  inject_into_file 'config/initializers/devise.rb', after: '# config.authentication_keys = [:email]' do
    "\n config.authentication_keys = [:email]\n"
  end

  inject_into_file 'config/initializers/devise.rb', after: '##config.clean_up_csrf_token_on_authentication = true' do
    "\n config.clean_up_csrf_token_on_authentication = true\n"
  end

  inject_into_file 'config/initializers/devise.rb', after: '# config.send_email_changed_notification = false' do
    "\n config.send_email_changed_notification = true\n"
  end
  inject_into_file 'config/initializers/devise.rb', after: '# config.send_password_change_notification = false' do
    "\n config.send_password_change_notification = true\n"
  end

  # Configuration for :invitable
  inject_into_file 'config/initializers/devise.rb', after: '# config.invite_for = 2.weeks' do
    "\n config.invite_for = 2.weeks\n"
  end
  inject_into_file 'config/initializers/devise.rb', after: '# config.invitation_limit = 5' do
    "\n config.invitation_limit = 5\n"
  end
  inject_into_file 'config/initializers/devise.rb', after: '# config.invite_key = { email: /\A[^@]+@[^@]+\z/ }' do
    "\n config.invite_key = { email: /\A[^@]+@[^@]+\z/ }\n"
  end
  inject_into_file 'config/initializers/devise.rb', after: '# config.validate_on_invite = true' do
    "\n config.validate_on_invite = true\n"
  end
  inject_into_file 'config/initializers/devise.rb', after: '# config.allow_insecure_sign_in_after_accept = false' do
    "\n config.allow_insecure_sign_in_after_accept = true\n"
  end

  # Configuration for :confirmable
  inject_into_file 'config/initializers/devise.rb', after: '# config.allow_unconfirmed_access_for = 2.days' do
    "\n config.allow_unconfirmed_access_for = 2.days\n"
  end
  inject_into_file 'config/initializers/devise.rb', after: '# config.confirm_within = 3.days' do
    "\n config.confirm_within = 3.days\n"
  end
  inject_into_file 'config/initializers/devise.rb', after: '# config.confirmation_keys = [:email]' do
    "\n config.confirmation_keys = [:email]\n"
  end

  puts "modifying environment configuration files for Devise..."
  gsub_file 'config/environments/development.rb', /# Don't care if the mailer can't send/, '# ActionMailer'

  insert_into_file 'config/environments/development.rb', after: /config\.action_mailer\.raise_delivery_errors = false\n/ do
    <<-RUBY
      config.action_mailer.asset_host = "http://localhost:3000"
      config.action_mailer.delivery_method = :letter_opener # Change :letter_opener to :smtp to test while in development
      config.action_mailer.perform_deliveries = true
      config.action_mailer.raise_delivery_errors = true
      config.action_mailer.default charset: "utf-8"
      #For Gmail to work, with ActionMailer base.
      config.action_mailer.smtp_settings = {
        :user_name => Rails.application.credentials.dig(:gmail_email),
        :password => Rails.application.credentials.dig(:gmail_password),
        :domain => 'your-domain-name.com',
        :address => "smtp.gmail.com",
        :port => "587",
        :authentication => "plain",
        :enable_starttls_auto => true, 
      }
    RUBY
  end

  gsub_file 'config/environments/production.rb', /config.i18n.fallbacks = true/ do
    <<-RUBY
      config.i18n.fallbacks = true
      # ActionMailer
      config.action_mailer.delivery_method = :smtp
      config.action_mailer.perform_deliveries = true
      config.action_mailer.raise_delivery_errors = false
      config.action_mailer.default charset: "utf-8"
      #For Gmail to work, with ActionMailer base.
      config.action_mailer.smtp_settings = {
        :user_name => ENV['gmail_email'],
        :password => ENV['gmail_password'],
        :domain => ENV['mail_host'],
        :address => "smtp.gmail.com",
        :port => "587",
        :authentication => "plain",
        :enable_starttls_auto => true,  
      }
      # Compress CSS using a preprocessor.
      config.assets.css_compressor = :sass
      # utilizes libsass to allow you to compile SCSS or SASS syntax to CSS
      SassC::Engine.new(sass, style: :compressed).render
      #require 'uglifier'
      config.assets.js_compressor = Uglifier.new(:harmony => true)
    RUBY
  end
end

def add_user_invitation
  generate "devise_invitable:install"
  generate "devise_invitable User"
  generate "devise_invitable:views"

  # Add Devise masqueradable to users
  inject_into_file("app/models/user.rb", "invitable, :", after: "devise :")

  puts "modifying environment configuration files for Devise..."
  gsub_file 'config/environments/development.rb', /# Don't care if the mailer can't send/, '# config.scoped_views = true'
end

# remove en.yml locale create by rails
remove_file 'config/locales/en.yml'

def add_webpack
  # Rails 6+ comes with webpacker by default, so we can skip this step
  return if rails_6?

  # Our application layout already includes the javascript_pack_tag,
  # so we don't need to inject it
  rails_command 'webpacker:install'
end

def add_features
  rails_command 'webpacker:install:stimulus'
  rails_command 'active_storage:install'
  rails_command 'action_text:install'
end

if options[:webpack]
  gsub_file "app/views/layouts/_head.html.erb", /^.*stylesheet_link_tag.*$/, <<-EOF
    = stylesheet_pack_tag 'application', media: 'all'#{", 'data-turbolinks-track': 'reload'" unless options[:skip_turbolinks]}
  EOF
end

def add_javascript
  run "yarn add expose-loader jquery popper.js bootstrap data-confirm-modal local-time @fortawesome/fontawesome-free @fullhuman/postcss-purgecss"

  if rails_5?
    run "yarn add turbolinks @rails/actioncable@pre @rails/actiontext@pre @rails/activestorage@pre @rails/ujs@pre"
  end

  content = <<-JS
    const webpack = require('webpack')
    environment.plugins.append('Provide', new webpack.ProvidePlugin({
      $: 'jquery',
      jQuery: 'jquery',
      Rails: '@rails/ujs'
    }))
  JS

  insert_into_file 'config/webpack/environment.js', content + "\n", before: "module.exports = environment"
end

def copy_templates
  copy_file "Procfile"
  copy_file "Procfile.dev"

  directory "app", force: true
  directory "config", force: true
  directory "lib", force: true
end

def add_tailwind
  # beta version for now
  run "yarn add tailwindcss"
  run "yarn add cookies-eu-banner"
  #run "mkdir -p app/javascript/stylesheets"
  copy_file 'app/javascript/stylesheets/application.scss'

  append_to_file 'app/javascript/packs/application.js', "\nrequire('packs/utils/custom.js')\n"
  append_to_file 'app/javascript/packs/application.js', "import '../stylesheets/application'\n"
  append_to_file 'app/javascript/packs/application.js', "import './utils/direct_uploads'\n"
  append_to_file 'app/javascript/packs/application.js', "import './utils/jquery_lazyload'\n"
  append_to_file 'app/javascript/packs/application.js', "import './utils/smooth_page_scrolling'\n"
  append_to_file 'app/javascript/packs/application.js', "import './utils/rails_admin/custom/ui'\n"
  append_to_file 'app/javascript/packs/application.js', "import CookiesEuBanner from 'cookies-eu-banner'\n"
  append_to_file 'app/javascript/packs/application.js', "import './utils/cookies_eu'\n"

  inject_into_file("./postcss.config.js",
  "let tailwindcss = require('tailwindcss');\n", before: "module.exports")
  inject_into_file("./postcss.config.js", "\n tailwindcss('./app/javascript/stylesheets/tailwind.config.js'),", after: "plugins: [")
end

def copy_postcss_config
  run "rm postcss.config.js"
  copy_file "postcss.config.js"
end

# Remove Application CSS
def remove_app_css
  remove_file "app/assets/stylesheets/application.css"
end

def add_i18n_routes
  content = <<-RUBY
    ## Uncomment to use letter_opener
    #if Rails.env.development?
    #  mount LetterOpenerWeb::Engine, at: "/letter_opener"
    #end

    scope "(:locale)", locale: /en|fi/ do # add all routes inside for locals
      root to: 'home#index'
      get '/about', to: 'home#about'
      get '/privacy', to: 'home#privacy'
      get '/terms', to: 'home#terms'
      get '/auth/:provider/callback', to: 'sessions#create'

      # rails_admin mount should be here!!!
      # Action cable for channels
      mount ActionCable.server => '/cable'
      #mount PdfjsViewer::Rails::Engine => "/pdfjs", as: 'pdfjs'

      ### To use errors handling links, please uncomment
      #route "match '/404', to: 'errors#not_found', via: :all"
      #route "match '/422', to: 'errors#unacceptable', via: :all"
      #route "match '/500', to: 'errors#server_error', via: :all"
    end
  RUBY
  insert_into_file "config/routes.rb", "#{content}\n\n", after: "Rails.application.routes.draw do\n"
end

def add_multiple_authentication
    insert_into_file "config/routes.rb",
    ', controllers: { omniauth_callbacks: "users/omniauth_callbacks", invitations: "invitations" }',
    after: "  devise_for :users"

    generate "model UserProvider user:references provider:string uid:string"
    
    template = """
    config.omniauth :facebook, ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_APP_SECRET'], scope: 'email', secure_image_url: true, image_size: 'square'
    config.omniauth :twitter, ENV['TWITTER_KEY'], ENV['TWITTER_SECRET'], scope: 'user,public_repo'
    config.omniauth :linkedin, 'APP_ID', 'APP_SECRET', scope: 'user,public_repo'
    config.omniauth :github, 'APP_ID', 'APP_SECRET', scope: 'user,public_repo'
    config.omniauth :google_oauth2, 'APP_ID', 'APP_SECRET', scope: 'user,public_repo'

    env_creds = Rails.application.credentials[Rails.env.to_sym] || {}
    %i{ facebook twitter github }.each do |provider|
      if options = env_creds[provider]
        config.omniauth provider, options[:app_id], options[:app_secret], options.fetch(:options, {})
      end
    end
    """.strip

    insert_into_file "config/initializers/devise.rb", "  " + template + "\n\n",
      before: "  # ==> Warden configuration"
end

def add_sidekiq
  environment "config.active_job.queue_adapter = :sidekiq"

  insert_into_file "config/routes.rb",
    "require 'sidekiq/web'\n\n",
    before: "Rails.application.routes.draw do"

  content = <<-RUBY
    authenticate :user, lambda { |u| u.admin? } do
      mount Sidekiq::Web => '/sidekiq'
    end
  RUBY
  insert_into_file "config/routes.rb", "#{content}\n\n", after: "mount ActionCable.server => '/cable'\n"
end

# Rails_admin theme
insert_into_file "config/application.rb", before: "Bundler.require(*Rails.groups)" do
  <<-RUBY
    #ENV['RAILS_ADMIN_THEME'] = 'rollincode'
  RUBY
end

# Handling error pages
insert_into_file 'config/application.rb', before: /^  end/ do
  <<-RUBY
  # Uncomment this for errors to work
  #require Rails.root.join('lib/custom_public_exceptions')
  #config.exceptions_app = CustomPublicExceptions.new(Rails.public_path)
  RUBY
end

=begin
def add_devise_tailwind
  run "rails generate devise:views:tailwindcssed"
end
=end

def add_cookies_eu
  run "bundle exec rails g cookies_eu:install"
end

def add_errors
  # Error handling links
  insert_into_file "config/routes.rb", before: /^  end/ do
    <<-RUBY
    ### To use errors handling links, please uncomment
    route "match '/404', to: 'errors#not_found', via: :all"
    #route "match '/422', to: 'errors#unacceptable', via: :all"
    #route "match '/500', to: 'errors#server_error', via: :all"
    RUBY
  end
end

# Public Error handling files
def remove_public_errors
  remove_file "public/404.html"
  remove_file "public/422.html"
  remove_file "public/500.html"
end

def add_meta
  generate "meta_tags:install"
end

def add_whenever
  run "wheneverize ."
end

def add_friendly_id
  generate "friendly_id"
  generate "migration AddSlugToUsers slug:uniq"
end

def add_demo_post
  rails_command 'g scaffold post title:string body:text --no-scaffold-stylesheet'
  generate "migration AddSlugToPosts slug:string:uniq"

  inject_into_file 'app/models/post.rb', after: 'ApplicationRecord' do
    "\n extend FriendlyId\n"
    "friendly_id :title, use: :slugged\n"
  end
end

def stop_spring
  run "spring stop"
end

def add_sitemap
  rails_command "sitemap:install"
end

def add_rails_admin
  run "rails g rails_admin:install"
end

# Main setup
add_template_repository_to_source_path

add_gems

after_bundle do
  set_application_name
  stop_spring
  add_users
  add_user_invitation
  add_webpack
  add_features
  add_javascript
  copy_templates
  add_tailwind
  copy_postcss_config
  remove_app_css
  add_sidekiq
  add_i18n_routes
  add_multiple_authentication
  add_friendly_id
  add_demo_post
  add_cookies_eu
  add_errors
  remove_public_errors
  add_meta
  add_whenever
  add_sitemap

  # Migrate
  rails_command "db:create"
  #rails_command "db:migrate"

  # Migrations must be done before this
  add_rails_admin

  # Commit everything to git
  git :init
  git add: "."
  git commit: %Q{ -m "Initial commit" }

  say
  say "#{app_name} app successfully created! 👍", :blue
  say
  say "** Please add `first_name last_name` code in README.md file - On `def uniqueslug` in `app/models/user.rb`."
  say
  say "To get started with your new app by typing:", :green
  say "$ cd #{app_name} - To switch to your new app's directory."
  say
  say "** Before running rails db:migrate open db/migrate/#_devise_create_users.rb and"
  say "Uncomment line under: ## Trackable, ## Confirmable & ## Lockable", :green
  say "$ rails db:migrate", :green
  say
  say "Then initialize your app by using:"
  say "$ rails server", :green
  say
  say "After that, head to your browser and type:"
  say "127.0.0.1:3000 or localhost:3000", :green
end
