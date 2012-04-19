source 'http://rubygems.org'
gem 'rails', '3.2.3'

# Bundle edge Rails instead:
# gem 'rails',     :git => 'git://github.com/rails/rails.git'

gem 'paperclip', "~>3.0.2"
gem 'aws-sdk'
gem 'kaminari'	# pagination
gem "devise", ">= 2.0.4" #AUTHENTICATION
gem "cancan" # MODEL PERMISSION

group :development, :test do
	gem 'heroku'
	gem 'mocha'
	gem 'watir-webdriver'
	#TESTING GEMS
	gem "rspec-rails", ">= 2.8.1"
end

gem 'amazon-mws', :git => 'git://github.com/aew/amazon-mws.git'
#gem 'RubyOmx', :git => 'git://github.com/aew/RubyOmx.git'

gem 'ruby_omx'
gem 'pg'
gem 'ruby-hmac'
gem 'roxml'
gem 'haml'
gem 'shopify_app'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  #gem 'sass-rails',   '3.1.4'
  gem 'sass-rails'
  #gem 'coffee-rails', '~> 3.1.1'
  gem 'coffee-rails'
  gem 'uglifier', '>= 1.0.3'
  gem 'therubyracer'
end

gem 'jquery-rails'


# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'

group :test do
	#gem 'turn', '0.8.2',:require => false	# Pretty printed test output
	gem 'turn', '0.9.5',:require => false
	gem 'simplecov', :require => false
	#gem 'rspec-rails'
	#gem 'shoulda'
	#gem 'fakeweb' 
	#TESTING GEMS
	gem "factory_girl_rails", ">= 1.7.0"
	gem "email_spec", ">= 1.2.1"
	gem "cucumber-rails", ">= 1.3.0", :require => false
	gem "capybara", ">= 1.1.2"
	gem "database_cleaner", ">= 0.7.1"
	gem "launchy", ">= 2.0.5" 
end
