insert_into_file 'config/application.rb', before: /^  end/ do
  <<-'RUBY'
    # CORS Config
    config.middleware.insert_before 0, Rack::Cors do
        allow do
          origins '*'
          resource '*', headers: :any, methods: %i[get post options delete]
        end
    end
    RUBY
end

insert_into_file 'config/application.rb', after: /Bundler\.require\(.+\)\n/ do
  <<-'RUBY'
# Load application ENV vars and merge with existing ENV vars. Loaded here so can use values in initializers.
begin
    ENV.update YAML.load_file('config/application.yml')[Rails.env]
rescue
    {}
end
    RUBY
end
