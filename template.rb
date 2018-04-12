require 'fileutils'
require 'shellwords'

RAILS_REQUIREMENT = '~> 5.1.6'.freeze
def apply_template!
  assert_minimum_rails_version
  assert_valid_options

  add_template_repository_to_source_path

  template 'Gemfile.tt', force: true

  if apply_capistrano?
    template 'DEPLOYMENT.md.tt'
    template 'PROVISIONING.md.tt'
  end

  template 'README.md.tt', force: true
  remove_file 'README.rdoc'

  # template 'example.env.tt'
  copy_file 'gitignore', '.gitignore', force: true
  copy_file 'overcommit.yml', '.overcommit.yml'
  template 'ruby-version.tt', '.ruby-version'
  copy_file 'simplecov', '.simplecov'

  copy_file 'Capfile' if apply_capistrano?
  copy_file 'Guardfile'

  apply 'config.ru.rb'
  apply 'bin/template.rb'
  apply 'config/template.rb'
  apply 'lib/template.rb'
  # apply 'test/template.rb'

  git :init unless preexisting_git_repo?
  empty_directory '.git/safe'

  run_with_clean_bundler_env 'bin/setup'

  generate_spring_binstubs

  binstubs = %w(
    annotate brakeman bundler bundler-audit guard rubocop sidekiq spec-core
  )
  binstubs.push('capistrano', 'unicorn') if apply_capistrano?
  run_with_clean_bundler_env "bundle binstubs #{binstubs.join(' ')} --force"

  template 'rubocop.yml.tt', '.rubocop.yml'
  run_rubocop_autocorrections

  return if any_local_git_commits?
  git add: '-A .'
  git commit: "-n -m 'Set up project'"

  return unless git_repo_specified?
  git remote: "add origin #{git_repo_url.shellescape}"
end

def assert_minimum_rails_version
  requirement = Gem::Requirement.new(RAILS_REQUIREMENT)
  rails_version = Gem::Version.new(Rails::VERSION::STRING)
  return if requirement.satisfied_by?(rails_version)

  prompt = "This template requires Rails #{RAILS_REQUIREMENT}. "\
           "You are using #{rails_version}. Continue anyway?"
  exit 1 if no?(prompt)
end

def assert_valid_options
  valid_options = {
    skip_gemfile: false,
    skip_bundle: false,
    skip_git: false,
    skip_test_unit: false,
    edge: false
  }
  valid_options.each do |key, expected|
    next unless options.key?(key)
    actual = options[key]
    unless actual == expected
      raise Rails::Generators::Error, "Unsupported option: #{key}=#{actual}"
    end
  end
end

def add_template_repository_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    require 'tmpdir'
    source_paths.unshift(tempdir = Dir.mktmpdir('rails-template-'))
    at_exit { FileUtils.remove_entry(tempdir) }
    git clone: [
      '--quiet',
      'https://github.com/kis25791/rails_api_template.git',
      tempdir
    ].map(&:shellescape).join(' ')

    if (branch = __FILE__[%r{rails-template/(.+)/template.rb}, 1])
      Dir.chdir(tempdir) { git checkout: branch }
    end
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

def apply_capistrano?
  return @apply_capistrano if defined?(@apply_capistrano)
  @apply_capistrano = \
    ask_with_default('Use Capistrano for deployment?', :blue, 'no') \
    =~ /^y(es)?/i
end

def capistrano_app_name
  app_name.gsub(/[^a-zA-Z0-9_]/, '_')
end

def git_repo_url
  @git_repo_url ||=
    ask_with_default('What is the git remote URL for this project?', :blue, 'skip')
end

def production_hostname
  @production_hostname ||=
    ask_with_default('Production hostname?', :blue, 'example.com')
end

def deployer_name
  @deployer_name ||=
    ask_with_default('Server Deployer name?', :blue, 'khoadeptrai')
end

# No Staging Server
# def staging_hostname
#   @staging_hostname ||=
#     ask_with_default('Staging hostname?', :blue, 'staging.example.com')
# end

def gemfile_requirement(name)
  @original_gemfile ||= IO.read('Gemfile')
  req = @original_gemfile[/gem\s+['"]#{name}['"]\s*(,[><~= \t\d\.\w'"]*)?.*$/, 1]
  req && req.tr("'", %(")).strip.sub(/^,\s*"/, ', "')
end

def ask_with_default(question, color, default)
  return default unless $stdin.tty?
  question = (question.split('?') << " [#{default}]?").join
  answer = ask(question, color)
  answer.to_s.strip.empty? ? default : answer
end

def git_repo_specified?
  git_repo_url != 'skip' && !git_repo_url.strip.empty?
end

def preexisting_git_repo?
  @preexisting_git_repo ||= (File.exist?('.git') || :nope)
  @preexisting_git_repo == true
end

def any_local_git_commits?
  system('git log &> /dev/null')
end

def run_with_clean_bundler_env(cmd)
  success = if defined?(Bundler)
              Bundler.with_clean_env { run(cmd) }
            else
              run(cmd)
            end
  return if success
  puts "Command failed, exiting: #{cmd}"
  exit(1)
end

def run_rubocop_autocorrections
  run_with_clean_bundler_env 'bin/rubocop -a --fail-level A > /dev/null || true'
end

apply_template!
