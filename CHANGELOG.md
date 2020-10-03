### 08.01.2020

* Adds support for Rails 6.0
* Move all Javascript to Webpacker for Rails 5.2 and 6.0
  * Use Bootstrap, data-confirm-modal, and local-time from NPM packages
  * ProvidePlugin sets jQuery, $, and Rails variables for webpacker
* Use https://github.com/excid3/administrate fork of Administrate
  * Adds fix for zeitwerk auto-loader in Rails 6
  * Adds support for virtual attributes
* Add welcome message and instructions after completion
