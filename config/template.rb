apply 'config/application.rb'
copy_file 'config/brakeman.yml'
copy_file 'config/sidekiq.yml'
copy_file 'config/application.yml'
# remove_file 'config/secrets.yml'
remove_file 'config/database.yml'
remove_file 'config/puma.rb'

if apply_capistrano?
  template 'config/deploy.rb.tt'
  template 'config/deploy/production.rb.tt'
  #   template 'config/deploy/staging.rb.tt'
end

copy_file 'config/initializers/secure_headers.rb'
copy_file 'config/initializers/version.rb'
template 'config/initializers/sidekiq.rb.tt'

gsub_file 'config/initializers/filter_parameter_logging.rb', /\[:password\]/ do
  '%w[password secret session cookie csrf]'
end

apply 'config/environments/development.rb'
apply 'config/environments/production.rb'
apply 'config/environments/test.rb'
# template 'config/environments/staging.rb.tt'

route %(mount Sidekiq::Web => "/sidekiq" # monitoring console\n)
