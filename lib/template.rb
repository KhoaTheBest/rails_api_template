if apply_capistrano?
  empty_directory_with_keep_file 'lib/capistrano/tasks'
  copy_file 'lib/capistrano/mb/templates/crontab.erb'
  copy_file 'lib/capistrano/mb/templates/maintenance.erb.html'
end
copy_file 'lib/tasks/coverage.rake'
