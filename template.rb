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
    #source_paths.unshift(File.dirname(__FILE__))
    [File.expand_path(File.dirname(__FILE__))]
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
  # Replace
  find_and_replace_in_file('Gemfile', "# gem 'bcrypt', '~> 3.1.7'", "gem 'bcrypt', '~> 3.1.7'")

  #find_and_replace_in_file('Gemfile', "# gem 'redis', '~> 4.0'", "gem 'redis', '~> 4.0'")

  find_and_replace_in_file('Gemfile', "# gem 'image_processing', '~> 1.2'", "gem 'image_processing', '~> 1.2'")

  # ADMIN
  gem 'rails_admin'
  gem 'rails_admin_rollincode'
  gem 'rails_admin-i18n'

  gem 'devise'
  gem 'devise_invitable'
  gem 'devise_masquerade'
  gem 'devise-i18n'
  gem 'devise-tailwindcssed'
  gem "pundit"
  gem 'font-awesome-sass'
  gem 'gravatar_image_tag', '~> 1.2'
  gem 'mini_magick', '~> 4.9', '>= 4.9.5'
  gem 'name_of_person'
  gem 'omniauth-facebook', '~> 5.0'
  gem 'omniauth-github', '~> 1.3'
  gem 'omniauth-twitter', '~> 1.4'
  gem 'omniauth-linkedin-oauth2', '~> 1.0'
  gem 'omniauth-google-oauth2', '~> 0.8.0'
  gem 'sidekiq'
  gem 'sitemap_generator'
  gem 'whenever', require: false
  gem 'friendly_id', '~> 5.4.0'
  #gem 'pdfjs_viewer-rails'
  gem 'sassc-rails'
  gem 'pagy'
  gem 'cookies_eu'
  gem 'uglifier'
  gem 'faker', '~> 2.7'
  ### Delivering static images through a CDN
  gem 'rack-cors'
  gem 'meta-tags'
  # locale data and translations to internationalize
  gem 'i18n'
  gem 'rails-i18n'

  inject_into_file 'Gemfile', after: "gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]" do
  "\n  gem 'dotenv-rails'
  gem 'letter_opener_web'
  gem 'pry-byebug'
  gem 'pry-rails'"
  end

  inject_into_file 'Gemfile', after: "gem 'web-console', '>= 3.3.0'" do
  "\n  gem 'listen', '>= 3.0.5', '< 3.2'
  #gem 'spring'
  #gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'wdm', '>= 0.1.0'
  gem 'dotenv', '~> 2.7', '>= 2.7.5'"
  end

  if rails_5?
    gsub_file "Gemfile", /gem 'sqlite3'/, "gem 'sqlite3'"
    #gem 'webpacker', '~> 4.0.1'
    gem 'webpacker'
  end
end

def stop_spring
  say "Stop spring if exists"
  run "spring stop"
end

# Database
say 'Applying postgresql...'
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
    config.time_zone = 'Helsinki'
    config.active_record.default_timezone = :local

    # Set locale
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    config.i18n.available_locales = [:fi, :en]
    config.i18n.default_locale = :en
    I18n.enforce_available_locales = true
  EOF
end

def add_users
  say 'Applying devise & creating User...'
  # Install Devise
  generate "devise:install"

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

  # install Devise locales
  remove_file 'config/locales/devise.en.yml'

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
  inject_into_file("app/models/user.rb", "invitable, :omniauthable, :masqueradable, :confirmable, 
          :lockable, :timeoutable, :", after: "devise :")
  inject_into_file("app/models/user.rb", ", omniauth_providers: [:linkedin, :twitter, :github, :google_oauth2]", after: ":validatable")

  inject_into_file 'app/models/user.rb', before: 'end' do
  "\n  enum role: [:user, :admin, :vip] # You can call your roles whatever you want. User will be 1, Admin will be 2, and VIP will be 3.
  after_initialize :set_default_role, :if => :new_record?

  def set_default_role
    self.role ||= :user
  end

  has_person_name
  validates_presence_of :name

  has_one_attached :avatar
  has_many :posts, dependent: :destroy
  has_many :user_provider, :dependent => :destroy
  before_save { self.email = email.downcase }

  # For friendly_id use
  def uniqueslug
    # Add here
  end

  # Add validations for the first and last name length
  validates :first_name, presence: true,
  length: { minimum: 2, maximum: 25 }

  validates :last_name, presence: true,
  length: { minimum: 2, maximum: 25 }

=begin
  # Now let’s add some password requirements:
  validate :password_complexity

  def password_complexity
    if password.present? and not password.match(/\A(?=.{8,})(?=.*\d)(?=.*\W+)(?=.*[a-z])(?=.*[A-Z])(?=.*[[:^alnum:]])/)
      errors.add :password, 'must include at 8 characters in total, one digit, one lower case letter, one uppercase letter, one non-character (such as !,#,%,@, etc), and no space.'
    end
  end
=end

  def avatar_url
    hash = Digest::MD5.hexdigest(email)
    'http://www.gravatar.com/avatar/#{hash}'
  end\n"
  end
  
  find_and_replace_in_file('config/initializers/devise.rb', "# config.mailer = 'Devise::Mailer'", "config.mailer = 'Devise::Mailer'")

  find_and_replace_in_file('config/initializers/devise.rb', "# config.parent_mailer = 'ActionMailer::Base'", "config.parent_mailer = 'ActionMailer::Base'")

  find_and_replace_in_file('config/initializers/devise.rb', '# config.authentication_keys = [:email]', 'config.authentication_keys = [:email]')

  find_and_replace_in_file('config/initializers/devise.rb', '# config.request_keys = []', 'config.request_keys = []')

  find_and_replace_in_file('config/initializers/devise.rb', '# config.clean_up_csrf_token_on_authentication = true', 'config.clean_up_csrf_token_on_authentication = true')

  find_and_replace_in_file('config/initializers/devise.rb', '# config.send_email_changed_notification = false', 'config.send_email_changed_notification = true')

  find_and_replace_in_file('config/initializers/devise.rb', '# config.send_password_change_notification = false', 'config.send_password_change_notification = true')

  # Configuration for :invitable
  find_and_replace_in_file('config/initializers/devise.rb', '# config.invite_for = 2.weeks', 'config.invite_for = 2.weeks')

  find_and_replace_in_file('config/initializers/devise.rb', '# config.invitation_limit = 5', 'config.invitation_limit = 5')

  find_and_replace_in_file('config/initializers/devise.rb', '# config.invite_key = { email: /\A[^@]+@[^@]+\z/ }', 'config.invite_key = { email: /\A[^@]+@[^@]+\z/ }')

  find_and_replace_in_file('config/initializers/devise.rb', '# config.validate_on_invite = true', 'config.validate_on_invite = true')

  find_and_replace_in_file('config/initializers/devise.rb', '# config.allow_insecure_sign_in_after_accept = false', 'onfig.allow_insecure_sign_in_after_accept = true')

  # Configuration for :confirmable
  find_and_replace_in_file('config/initializers/devise.rb', '# config.allow_unconfirmed_access_for = 2.days', 'config.allow_unconfirmed_access_for = 2.days')

  find_and_replace_in_file('config/initializers/devise.rb', '# config.confirm_within = 3.days', 'config.confirm_within = 3.days')

  find_and_replace_in_file('config/initializers/devise.rb', '# config.confirmation_keys = [:email]', 'config.confirmation_keys = [:email]')

  puts "modifying environment configuration files for Devise..."
  gsub_file 'config/environments/development.rb', /# Don't care if the mailer can't send/, '# ActionMailer'

  ## development.rb
  inject_into_file 'config/environments/development.rb', after: 'Rails.application.configure do' do
    "\nconfig.action_mailer.default_url_options = { host: 'localhost', port: 3000 }"
  end

  insert_into_file 'config/environments/development.rb', after: /config\.action_mailer\.raise_delivery_errors = false\n/ do
  <<-RUBY
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

def find_and_replace_in_file(file_name, old_content, new_content)
  text = File.read(file_name)
  new_contents = text.gsub(old_content, new_content)
  File.open(file_name, 'w') { |file| file.write new_contents }
end

def add_user_invitation
  say 'Applying devise invitable...'

  generate "devise_invitable:install"
  generate "devise_invitable User"
  generate "devise_invitable:views"

  # Add Devise masqueradable to users
  inject_into_file("app/models/user.rb", "invitable, :", after: "devise :")

  puts "modifying environment configuration files for Devise..."
  gsub_file 'config/environments/development.rb', /# Don't care if the mailer can't send/, '# config.scoped_views = true'
end

## Assets.rb
def add_assets
  inject_into_file 'config/initializers/assets.rb', after: '# Rails.application.config.assets.precompile += %w( admin.js admin.css )' do
  "\nRails.application.config.assets.precompile += %w( application.js application.scss )"
  end
end

# Not added
def add_application_js
  say 'Create & Adding require_* statements...'

  FileUtils.mkdir_p('app/assets/javascripts')
  app_js = 'app/assets/javascripts/application.js'
  FileUtils.touch(app_js)

  append_to_file app_js do
  '//= require jquery
  //= require jquery3
  //= require jquery_ujs
  //= require moment
  //= require moment/ja.js
  //= require bootstrap-datetimepicker
  //= require turbolinks
  //= require cookies_eu
  //= require_tree .'
  end
end

# remove en.yml locale create by rails
say 'Removing intalled en.yml file...'
remove_file 'config/locales/en.yml'

# Check if rails 6 & install webpacker
def add_webpack
  say 'Check if rails 6 else install webpacker...'

  # Rails 6+ comes with webpacker by default, so we can skip this step
  return if rails_6?

  # Our application layout already includes the javascript_pack_tag,
  # so we don't need to inject it
  rails_command 'webpacker:install'
end

# Install feature via yarn or npm
def add_features
  say 'Installing stimulus, active_storage, & action_text via yarn or npm...'

  rails_command 'webpacker:install:stimulus'
  rails_command 'active_storage:install'
  rails_command 'action_text:install'
end

def copy_templates
  say 'Copying files & folders...'
  #copy_file "Procfile"
  #copy_file "Procfile.dev"

  directory "app", force: true
  directory "config", force: true
  directory "lib", force: true
  directory "public", force: true
end

# Add Action text to application.scss
def add_action_text
  say 'Adding action text require statement...'
  inject_into_file 'app/assets/stylesheets/application.scss', before: '// $navbar-default-bg: #312312;' do
  "//= require actiontext\n"
  end

  say 'Adding pack_tags to the layout header...'
  if options[:webpack]
    gsub_file "app/views/layouts/_head.html.erb", /^.*stylesheet_link_tag.*$/, <<-EOF
      = stylesheet_pack_tag 'application', media: 'all'#{", 'data-turbolinks-track': 'reload'" unless options[:skip_turbolinks]}
    EOF
  end
end

def add_javascript
  say 'Installing javaScript modules via yarn or npm...'

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

def add_tailwind
  say 'Installing tailwindcss modules via yarn or npm & append imports...'
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
=begin
  inject_into_file("./postcss.config.js",
  "let tailwindcss = require('tailwindcss');\n", before: "module.exports")
  inject_into_file("./postcss.config.js", "\n tailwindcss('./app/javascript/stylesheets/tailwind.config.js'),", after: "plugins: [")
=end
end

def copy_postcss_config
  say 'Removing initial postcss.config.js file...'
  run "rm postcss.config.js"
  copy_file "postcss.config.js"
end

# Remove Application CSS
def remove_app_css
  say 'Removing initial application.css file...'
  remove_file "app/assets/stylesheets/application.css"
end

def add_i18n_routes
  say 'Adding routes...'

  content = <<-RUBY
  root to: 'home#index'
  get '/about', to: 'home#about'
  get 'contact', to: 'contacts#new', as: 'new_contact'
  post 'contact', to: 'contacts#create', as: 'create_contact'
  get '/privacy', to: 'home#privacy'
  get '/terms', to: 'home#terms'
  get '/auth/:provider/callback', to: 'sessions#create'

  # rails_admin mount should be here!!!
  # Action cable for channels
  mount ActionCable.server => '/cable'
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
    #route "match '/404', to: 'errors#not_found', via: :all"
    #route "match '/422', to: 'errors#unacceptable', via: :all"
    #route "match '/500', to: 'errors#server_error', via: :all"
    RUBY
  end
end

# Public Error handling files
def remove_public_errors
  #remove_file "public/404.html"
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

def add_friendly_to_user
  inject_into_file 'app/models/user.rb', after: "class User < ApplicationRecord" do
  "\n  extend FriendlyId
  friendly_id :uniqueslug, use: :slugged\n"
  end
end
  
def add_change_in_friendly_id
  find_and_replace_in_file('config/initializers/friendly_id.rb', '# config.use :finders', 'config.use :finders')
  find_and_replace_in_file('config/initializers/friendly_id.rb', '# config.use :slugged', 'config.use :slugged')
end

def add_demo_post
  rails_command 'g scaffold post title:string author:string --no-scaffold-stylesheet' #user:references Or user_id:integer
  generate "migration AddSlugToPosts slug:string:uniq"

  # Post Model
  inject_into_file 'app/models/post.rb', after: 'class Post < ApplicationRecord' do
  "\n  require 'faker'\n
  extend FriendlyId
  friendly_id :title, use: :slugged
  
  has_rich_text :description
  #belongs_to :user

  has_one_attached :main_image

  validates_presence_of :title, :description, :author
  #validates :description, presence: true, length: {minimum: 50, maximum: 10320 }
  validates_length_of :description, within: 50..10320

  def self.recent
    #order('created_at DESC')
    order('updated_at DESC')
  end

  def avatar_url
    hash = Digest::MD5.hexdigest(email)
    'http://www.gravatar.com/avatar/#{hash}'
  end

  def previous
    Post.where(['id < ?', id]).last
  end

  def next
    Post.where(['id > ?', id]).first
  end

  def rand_time(from, to=Time.now)
    Time.at(rand_in_range(from.to_f, to.to_f))
  end\n"
  end

  # Posts Controller
  find_and_replace_in_file(
    'app/controllers/posts_controller.rb', 
    '@post = Post.find(params[:id])', 
    '@post = Post.friendly.find(params[:id]) rescue server_error'
  )
  find_and_replace_in_file(
    'app/controllers/posts_controller.rb', 
    'params.require(:post).permit(:title)', 
    'params.require(:post).permit(:title, :author, :main_image, :description, :user_id, :slug)' #:user_id,
  )

  find_and_replace_in_file(
    'app/controllers/posts_controller.rb', 
    'format.html { render :new }', 
    'format.html { broadcast_errors @post, post_params }'
  )

  inject_into_file 'app/controllers/posts_controller.rb', after: "before_action :set_post, only: [:show, :edit, :update, :destroy]" do
    "\nbefore_action :authenticate_user!, except: [:show, :index]"
  end

  inject_into_file 'app/controllers/posts_controller.rb', after: "@posts = Post.all" do
    "\n\n  # Meta Tags & dynamic page title
    @page_title = t('post_page')"
  end

  inject_into_file 'app/controllers/posts_controller.rb', after: "def show" do
    "\n   # Meta Tags & dynamic page title
    @page_title = @post.title
    @page_description = @post.description
    @page_keywords = @post.description"
  end
end

def remove_post_form_and_show
  remove_file "app/views/posts/_form.html.erb"
  remove_file "app/views/posts/show.html.erb"
  remove_file "app/views/posts/index.html.erb"
  remove_file "app/views/posts/new.html.erb"
  remove_file "app/views/posts/edit.html.erb"
end

def create_post_form
  #FileUtils.mkdir_p('app/views/posts')
  post_form = 'app/views/posts/_form.html.erb'
  FileUtils.touch(post_form)
  append_to_file post_form do
  '<%= form_with(model: post) do |form| %>
  <div class="-mx-3 md:flex mb-6">
    <div class="field md:w-1/2 px-3 mb-6 md:mb-0 border shadow-sm p-2">
      <%= form.label :author %>:<br />
      <%= form.text_field :author, class: "form-control appearance-none block w-full bg-grey-lighter text-grey-darker border border-grey-lighter rounded py-3 px-4" %>
      <%= form.error_for :author %>
    </div>

    <div class="field md:w-1/2 px-3 ml-2 mb-6 md:mb-0 border shadow-sm p-2">
      <%= form.label :title %>:<br />
      <%= form.text_field :title, class: "form-control appearance-none block w-full bg-grey-lighter text-grey-darker border border-grey-lighter rounded py-3 px-4" %>
      <%= form.error_for :title, class:"text-danger" %>
    </div>
  </div>

  <div class="-mx-3 md:flex mb-6">
    <div class="field md:w-1/2 px-3 mb-6 md:mb-0 border shadow-sm p-2">
      <%= form.label :main_image %>: <br />
      <%= form.file_field :main_image, direct_upload: true, class: "form-control appearance-none block w-full bg-grey-lighter text-grey-darker border border-grey-lighter rounded py-3 px-4" %>
    </div>
  </div>

  <div class="field form-group">
    <%= form.label :description %>
    <%= form.rich_text_area :description, class: "form-control", placeholder: "Write your story" %>
    <%= form.error_for :description %>
    <%= form.error_for :title, class:"text-red-600" %>
  </div>
  <br />

  <div class="field -mx-3 md:flex mb-6 mt-4">
    <%= form.submit "👋 Save Post", class: "m-2 text-gray-800 font-bold rounded border-b-2 border-green-500 hover:border-green-600 hover:bg-green-500 hover:text-white no-underline hover:no-underline shadow-md py-2 px-6 inline-flex items-center", data: {disable_with: "Saving..."} %>

    <% if post.persisted? %>
      <%= link_to "Cancel", post, class: "m-2 text-gray-800 font-bold rounded border-b-2 border-yellow-500 hover:border-yellow-600 hover:bg-yellow-600 hover:text-white no-underline hover:no-underline shadow-md py-2 px-6 inline-flex items-center" %>
    <% else %>
      <%= link_to "Cancel", posts_path, class: "m-2 text-gray-800 font-bold rounded border-b-2 border-yellow-500 hover:border-yellow-600 hover:bg-yellow-600 hover:text-white no-underline hover:no-underline shadow-md py-2 px-6 inline-flex items-center" %>
    <% end %>

    <% if post.persisted? %>
      <div class="float-right">
        <%= link_to "Destroy", post, method: :delete, class: "m-2 text-gray-800 font-bold rounded border-b-2 border-red-500 hover:border-red-600 hover:bg-red-500 hover:text-white no-underline hover:no-underline shadow-md py-2 px-6 inline-flex items-center", data: { confirm: "Are you sure?" } %>
      </div>
    <% end %>
    <br />
  </div>
<% end %>'
  end
end

def create_post_show
  #FileUtils.mkdir_p('app/views/posts')
  post_show = 'app/views/posts/show.html.erb'
  FileUtils.touch(post_show)
  append_to_file post_show do
  '<% set_meta_tags og: {
  title: @post.title,
  description: @post.description,
  type:     "article",
  url:      "posts_url(@post)",
  image:    "https://onebitcode.com/meu-seo/img.png",
} %>
<br>
<!--Container-->
<div class="container w-full flex flex-wrap mx-auto px-2 rounded-sm bg-transparent">
  <div class="w-full lg:w-1/6 lg:mx-2 text-xl text-gray-800 leading-normal">
    <!--Sticky topics-->
    <div class="sticky bg-white hidden h-64 lg:h-auto overflow-x-hidden overflow-y-auto lg:overflow-y-hidden lg:block mt-0 y-20 shadow-sm rounded-sm" style="top:5em;" id="menu-content">
      <div class="list-reset ml-2 my-2">
        <%= link_to posts_path, class: "text-base md:text-sm text-indigo-500 font-bold ml-4" do %>
          <span class="text-base text-indigo-500 font-bold">&laquo;<span> <%= t".back_link" %>
        <% end %>

        <div class="mt-5 flex lg:mt-0 lg:ml-4">
          <span class="hidden sm:block shadow-sm rounded-md">
            <%= link_to icon("fab", "readme"), posts_path, type: "button", class: "inline-flex items-center px-4 py-2 border border-gray-300 text-sm leading-5 font-medium rounded-md text-gray-700 bg-white hover:text-red-600 focus:outline-none focus:shadow-outline-blue focus:border-blue-300 active:text-gray-800 active:bg-gray-50 active:text-gray-800 transition duration-150 ease-in-out" %>
          </span>
          <% if admin? %>
            <span class="hidden sm:block ml-3 shadow-sm rounded-md">
              <%= link_to icon("far", "edit"), edit_post_path(@post), type: "button", class: "inline-flex items-center px-4 py-2 border border-gray-300 text-sm leading-5 font-medium rounded-md text-gray-700 bg-white hover:text-gray-500 focus:outline-none focus:shadow-outline-blue focus:border-blue-300 active:text-gray-800 active:bg-gray-50 transition duration-150 ease-in-out", title: "Edit post" %>
            </span>

            <span class="hidden sm:block ml-3 shadow-sm rounded-md">
              <%= link_to icon("far", "trash-alt"), @post, method: :delete, data: { confirm: "Are you sure you want to delete this?" }, type: "button", class: "inline-flex items-center px-4 py-2 border border-gray-300 text-sm leading-5 font-medium rounded-md text-gray-700 bg-white hover:text-red-600 focus:outline-none focus:shadow-outline-blue focus:border-blue-300 active:text-gray-800 active:bg-gray-50 active:text-gray-800 transition duration-150 ease-in-out" %>
            </span>
          <% end %>
        </div>
      </div>
    </div>
  </div>
  <div class="w-full lg:w-4/5 p-8 mt-6 lg:mt-0 text-gray-900 leading-normal bg-white border border-gray-400 border-rounded rounded-sm">
    <!--Title-->
    <div class="font-sans">
      <h1 class="text-center font-sans font-bold text-indigo-500 pt-2 text-2xl capitalize">
        <span class="hover:text-teal-500">👋 <%= title @post.title %></span>
      </h1>
      <span class="ml-2"><%= t".min_read" %> · <%= time_ago_in_words(3.minutes.from_now) %> <%= t".post_time" %></span>
    </div>
    <hr class="border-b border-gray-400">
    <!--image-->
    <div class="container w-full max-w-6xl mx-auto bg-cover mt-4 rounded">
      <%= image_tag @post.main_image, title: "#{@post.title}", alt: "#{@post.title} by #{@post.author}", style: "h-full w-full object-cover background-image rounded shadow-md", height: "75vh" if @post.main_image.attached? %>
    </div>
    
    <!--blog Content-->
    <p class="py-2 ex3 blog-content">
      <%= @post.description %>
    </p>
    <!--/ blog Content-->
    <hr class="border-b border-indigo-500 mt-3">
    <section class="mt-3 container mx-auto flex items-center justify-around">
      <div>
        <div class="flex rounded border-b-2 border-grey-600 overflow-hidden">
          <% if @post.previous %>
            <div class="bg-yellow-400 shadow-border p-2">
              <div class="w-4 h-4">
                <<
              </div>
            </div>
            <%= link_to t(".prev_link", :default => "Previous"), @post.previous, class: "block text-gray-800 text-bg hover:shadow shadow-border bg-gray-200 hover:bg-yellow-400 hover:no-underline text-bg py-2 px-4 font-sans tracking-wide font-bold" %>
          <% end %>
        </div>
      </div>
      <div>
        <div class="flex rounded border-b-2 border-grey-600 overflow-hidden">
          <% if @post.next %>
            <%= link_to t(".next_link", :default => "Next"), @post.next, class: "block text-gray-800 text-bg hover:bg-gray-200 hover:shadow shadow-border bg-gray-200 hover:bg-teal-400 hover:no-underline text-bg py-2 px-4 font-sans tracking-wide font-bold" %>
            <div class="bg-teal-400 shadow-border p-2">
              <div class="w-4 h-4">
                >>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </section>
    
    <hr class="mt-2">
    <!--Author-->
    <div class="flex w-full bg-white items-center font-sans">
      <%= image_tag "https://i.pravatar.cc/300", alt: "Avatar of Author", class: "w-10 h-10 rounded-full avatar mr-4 mt-2" %>     
      
      <!-- root_admin_user.first_name -->
      <div class="flex-1">
        <%= link_to t(".follow_btn", :default => "Follow"), new_user_session_path, class: "bg-transparent hover:shadow border border-gray-500 hover:border-teal-500 hover:no-underline text-xs text-gray-500 hover:text-teal-500 font-bold py-2 px-4 mb-3 rounded-full" if @current_user.nil? %>
        <p class="text-sm leading-none mt-3">
          <%= t".created_by" %> <b><%= @post.author unless @post.author.blank? %></b>
        </p>
      </div>
      <div class="justify-end">
        <%= link_to posts_path, class: "bg-transparent hover:shadow border border-gray-500 hover:border-indigo-500 text-xs text-gray-500 hover:text-indigo-500 font-bold py-2 px-4 rounded-full" do %>
          <%= t".browse_mo" %>
        <% end %>
      </div>
    </div>
    <!--/Author-->

    <!--Back link -->
    <div class="w-full lg:w-4/5 lg:ml-auto text-base md:text-sm text-gray-500 px-4 py-6">
      <div class="pull-right text-base md:text-sm text-indigo-500 font-bold">
        <%= link_to t("go_back", :default => "<< Go back"), :back %>
      </div>
    </div>
  </div>
</div>
<!--/container-->'
  end
end

def create_post_index
  #FileUtils.mkdir_p('app/views/posts')
  post_index = 'app/views/posts/index.html.erb'
  FileUtils.touch(post_index)
  append_to_file post_index do
  '<!--Posts Container-->
<div class="container flex flex-wrap justify-between" style="margin-top: 2rem;">
  <div class="text-center container">
    <h2 class="font-bold break-normal text-3xl md:text-5xl"><u><%=t ".page_title" %></u></h2>
    <p class="lead post-description"><%=t ".post_discrip" %></p>
  </div>
  
  <%# if user_signed_in? && current_user %>
  <%# if user_signed_in? %>
  <% if admin? %>
    <div class="flex flex-col flex-grow flex-shrink w-full">
      <%= link_to new_post_path, class: "block w-full text-center py-2 rounded shadow-md bg-green-400 text-white hover:bg-green-600 focus:outline-none my-1 hover:no-underline" do %>
        <i class="pencil alternate icon"></i> 
        Add New Post
      <% end %>
    </div>
  <% end %>
</div>

<section class="py-12 px-4">
  <div class="flex flex-wrap -mx-4">
    <% if @posts.count == 0 %>
      <h2 class="text-center text-yellow-600 font-serif"> There are no <b>Posts</b> yet! we will publish soon. <br> Please check back later.</h2>
    <% else %>
      <% @posts.each do |post| %>
        <%= content_tag :tr, id: dom_id(post), class: dom_class(post) do %>
          <div class="w-full lg:w-1/3 px-4 mb-8 lg:mb-8">
            <div class="h-full pb-8 mt-5 rounded shadow-md">
              <a href="<%= post_path(post) %>">
                <% if post.main_image.attached? %>
                  <%= image_tag post.main_image, title: "#{post.title}", alt: "#{post.title} by #{post.author}", class: "mb-4" %>
                <% else %>
                  <!-- Show nothing -->
                <% end %>
                <div class="px-6">
                  <small>
                    <%= post.created_at.strftime("%b %d, %Y") %> | <%= t".created_by" %> <%= post.author unless post.author.blank? %>
                  </small>
                  <h3 class="text-xl my-3 font-heading">
                    <%= link_to post.title, post_path(post) %>
                  </h3>
                  <p class="text-gray-500">
                    <%= truncate(strip_tags(post.description.to_s), length:356, escape: false, omission: "... (continued)") %>
                  </p>
                </div>
              </a>
              <div class="px-4 mb-8 mt-4 lg:mb-0 justify-end">
                <button>
                  <%= link_to post_path(post), class: "bg-transparent hover:shadow border border-gray-500 hover:border-teal-500 hover:no-underline text-xs text-gray-500 hover:text-teal-500 font-bold py-2 px-4 rounded-full shadow-md", data: {disable_with: "Loading..."} do %>
                    <%= t".read_btn", :default => "Read more »" %>
                  <% end %>
                </button>
              </div>
            </div>
          </div>
        <% end %>
      <% end %>
    <% end %>
  </div>
</section>'
  end
end

def create_post_new
  #FileUtils.mkdir_p('app/views/posts')
  post_new = 'app/views/posts/new.html.erb'
  FileUtils.touch(post_new)
  append_to_file post_new do
  '<div class="font-sans container mt-10">
  <div class="w-full content-center flex shadow-lg flex-col bg-cover bg-center bg-white p-6 rounded pt-8 pb-1">
    <div class="text-center text-grey mb-6">
      <h1>New Post</h1>
    </div>

    <%= render "form", post: @post %>
  </div>
</div>'
  end
end

def create_post_edit
  #FileUtils.mkdir_p('app/views/posts')
  post_edit = 'app/views/posts/edit.html.erb'
  FileUtils.touch(post_edit)
  append_to_file post_edit do
  '<div class="font-sans container mt-10">
  <div class="w-full content-center flex shadow-lg flex-col bg-cover bg-center bg-white p-6 rounded pt-8 pb-1">
    <div class="text-center text-grey mb-6">
      <h1>Edit Post</h1>
    </div>

    <%= render "form", post: @post %>
  </div>
</div>'
  end
end

def add_mailer
  contact = 'app/mailers/contact_mailer.rb'
  FileUtils.touch(contact)

  append_to_file contact do
  'class ContactMailer < ApplicationMailer
  def contact_me(message)
    @name = message.name
    @email = message.email
    @sent_on = Time.now
    @subject = message.subject
    @body = message.body
    @url  = "https://your-app-url.com/"
    @greeting = "Hello!"

    mail to: "no-reply@example.com", from: message.email
  end
end'
  end
end

def add_sitemap
  rails_command "sitemap:install"
end

def add_letter_opener
  # letter_opener
  insert_into_file "config/routes.rb", after: "Rails.application.routes.draw do\n" do
  <<-RUBY
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
  RUBY
  end
end

def add_form_friendlier_errors
  say 'Applying Optimism Gem...'
  run "bundle add optimism"
  run "yarn add cable_ready"
  run "rake optimism:install"
end

def add_pdfjs
  say 'Applying pdfjs_viewer-rails...'
  find_and_replace_in_file('Gemfile', "gem 'sass-rails', '>= 6'", "gem 'sass-rails', '~> 5.0'")
  run "bundle update"

  gem 'pdfjs_viewer-rails'
  inject_into_file 'config/routes.rb', after: "mount ActionCable.server => '/cable'\n" do <<-EOF
    mount PdfjsViewer::Rails::Engine => "/pdfjs", as: 'pdfjs'
  EOF
  end
end

def add_unique_slug
  # Unique_slug
  inject_into_file 'app/models/user.rb', after: "def uniqueslug\n" do <<-EOF
    '#{first_name}-#{last_name}'
  EOF
  end
end

def add_rails_admin
  run "rails g rails_admin:install"
  run "bundle exec rails g cookies_eu:install"

  # Rails_admin theme
  inject_into_file 'config/application.rb', after: "# you've limited to :test, :development, or :production.\n" do <<-EOF
    ENV['RAILS_ADMIN_THEME'] = 'rollincode'
  EOF
  end
end

# Main setup
add_template_repository_to_source_path

say 'Applying gems...'
add_gems

after_bundle do
  set_application_name
  stop_spring
  add_users
  add_user_invitation
  add_assets
  add_webpack
  add_features
  copy_templates
  add_javascript
  copy_postcss_config
  add_tailwind
  remove_app_css
  add_sidekiq
  add_i18n_routes
  add_multiple_authentication
  add_friendly_id
  add_friendly_to_user
  add_change_in_friendly_id
  add_demo_post
  remove_post_form_and_show
  create_post_form
  create_post_show
  create_post_index
  create_post_new
  create_post_edit
  add_cookies_eu
  add_errors
  remove_public_errors
  add_meta
  add_whenever
  add_mailer
  add_sitemap
  add_form_friendlier_errors
  add_pdfjs

  say 'Almost done! Now init `git` and `database`...'
  # Migrate
  rails_command "db:create"
  #rails_command "db:migrate"

  # Migrations must be done before this
  add_action_text
  add_letter_opener
  #add_unique_slug
  add_rails_admin

  # Commit everything to git
  git :init
  git add: "."
  git commit: '-m "init rails with rails-template"'

  say
  say "#{app_name} Build successfully! 👍", :blue
  say
  say "⚠  Attention: Please add `first_name last_name` code in README.md file - On `def uniqueslug` in `app/models/user.rb`.", :red
  say
  say "To get started with your new app by typing:", :green
  say "First cd #{app_name} - To switch to your new app's directory."
  say
  say "⚠  Attention: Before running rails db:migrate open db/migrate/*_devise_create_users.rb and"
  say "Uncomment line under: ## Trackable, ## Confirmable & ## Lockable for more info read the README.md file", :red
  say "run: rails db:migrate", :green
  say
  say "Then initialize your app by using:"
  say "Start `./bin/webpack-dev-server` first then `rails s` to start your rails app...", :green
  say
  say "After that, head to your browser and type:"
  say "127.0.0.1:3000 or localhost:3000", :green
end
