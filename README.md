```ruby
=begin
#######################################################################################################################
##  ####  ####      ##########       ##      ####      ###  ##############      ##########         ###  ##########  ###
##  ###  ####  ####  ########  ####  ##  ########  #######  #############  ####  #########  ##########  ##########  ###
##  ##  ####  ######  ######  #####  ##  ########  #######  ############  ######  ########  ##########  ##########  ###
##  #  ####  ########  ####  ######  ##  ########  #######  ###########  ########  #######  ##########  ##########  ###
##  ######  ##########  ##  #######  ##      ####      ###  ##########  ##########  ######         ###  ###    ###  ###
##  #  ####  ########  ####  ######  ##  ########  #######  #########  ###      ###  ############  ###  ##########  ###
##  ##  ####  ######  ######  #####  ##  ########  #######  ########  ###        ###  ###########  ###  ##########  ###
##  ###  ####  ####  ########  ####  ##  ########  #######  #######  ###          ###  ##########  ###  ##########  ###
##  ####  ####      ##########       ##      ####  #######       ##  ###           ###  ##         ###  ##########  ###
#######################################################################################################################
=end
```

# Rails kodeflash – Tailwindcss

A rapid Rails (6.0.2.1) application template that saves loads of time creating your next Rails application. This particular template utilizes [Tailwind CSS](https://tailwindcss.com/), a utility-first CSS framework for rapid UI development.

Tailwind depends on Webpack so this also comes bundled with [webpacker](https://github.com/rails/webpacker) support.

Inspired heavily by [Jumpstart](https://github.com/excid3/jumpstart) from Chris Oliver. Credits to him.

## Getting Started

Kodeflash is a Rails template will generated with Tailwind CSS by [Rodney H](https://kodeflash.com).

#### 👉 Requirements

You'll need the following installed to run the template successfully:

- Ruby 2.5 or higher
- Redis - For ActionCable support
- bundler - `gem install bundler`
- rails - `gem install rails`
- Yarn - `npm install yarn` or [Install Yarn](https://yarnpkg.com/en/docs/install)

#### Creating a new app

```bash
rails new app-name -d postgresql -m https://raw.githubusercontent.com/Rodcode47/kodeflash-Rails-template/master/template.rb
```

❓ If for some reason the URL above fails, we recommend you have downloaded this repo, you can reference template.rb locally by:

- unzip the downloaded file (kodeflash-Rails-template).
- cd kodeflash-Rails-template
- Then initialize your New App by using:

```bash
rails new app-name -d postgresql -m template.rb
```

#### ❓ Once your app is created what do next?

- Add in to file `'app/models/user.rb'` inside `def uniqueslug`

```ruby
# For friendly_id use
def uniqueslug
  "#{first_name}-#{last_name}" # Add this line!!! in app/models/user.rb
end
```

- cd #{app_name} - into your new app's directory.
- Then initialize your app by using: `$ rails server`
- After that, head to your browser and type: `127.0.0.1:3000 or localhost:3000`

❓ If the app fails due to **Segmentation fault**? try running `$ rails server` again Or Try adding `DISABLE_SPRING=1` before `rails new`. Spring will get confused if you create an app with the same name twice.

#### Once installed what do I get?

- Webpack support + Tailwind CSS configured in the `app/javascript` directory.
- Devise with a new `username`, `name`, `invitation`, `omniauth` field already migrated in. Enhanced views using Tailwind CSS.
- Support for Friendly IDs thanks to the handy [friendly_id](https://github.com/norman/friendly_id) gem. Note that you'll still need to do some work inside your models for this to work. This template installs the gem and runs the associated generator.

- Rails 6+ comes with webpacker by default and some cool features like `active_storage`, `action_text` which we added for you to use `has_one_attached` or `has_rich_text`. Note that you'll still need to do some work inside your models for this to work. This template installs the gem and runs the associated generator.
- Optional Foreman support thanks to a `Profile`. Once you scaffold the template, run `foreman start` to initialize and head to `localhost:5000` to get `rails server`, `sidekiq` and `webpack-dev-server` running all in one terminal instance. Note: Webpack will still compile down with just `rails server` if you don't want to use Foreman. Foreman needs to be installed as a global gem on your system for this to work. i.e. `gem install foreman`
- A custom scaffold view template when generating theme resources (Work in progress).

* Git initialization out of the box

###### Included gems

- [devise](https://github.com/plataformatec/devise)
- [OmniAuth: multiple-provider authentication](https://rubygems.org/search?utf8=%E2%9C%93&query=omniauth)
- [devise_invitable](https://github.com/scambra/devise_invitable)
- [friendly_id](https://github.com/norman/friendly_id)
- [sidekiq](https://github.com/mperham/sidekiq)
- [rails_i18n](https://github.com/svenfuchs/rails-i18n)
- [meta-tags](https://github.com/kpumuk/meta-tags)
- [lazyload-rails](https://github.com/jassa/lazyload-rails)
