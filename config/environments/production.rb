uncomment_lines 'config/environments/production.rb',
                /config\.action_dispatch\.x_sendfile_header = 'X-Accel-Redirect' # for NGINX/i
uncomment_lines 'config/environments/production.rb', /config\.force_ssl = true/

# insert_into_file 'config/environments/production.rb',
#                  after: /# config\.action_mailer\.raise_deliv.*\n/ do
#   <<-RUBY
#   # Production email config
#   config.action_mailer.delivery_method = :postmark
#   config.action_mailer.postmark_settings = {
#     api_token: ENV.fetch("POSTMARK_API_KEY")
#   }
#   config.action_mailer.raise_delivery_errors = true
#   config.action_mailer.default_url_options = {
#     host: "#{production_hostname}",
#     protocol: "https"
#   }
#   config.action_mailer.asset_host = "https://#{production_hostname}"
#   RUBY
# end
