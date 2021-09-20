require 'yaml'
require 'fileutils'

# You may want to change this.
def modules_path(environment)
  File.join('hcl_template', environment, 'modules')
end

# You may want to change this.
def terrafile_path(environment)
  File.join('hcl_template', environment, 'Terrafile')
end

def read_terrafile(environment)
  if File.exist? terrafile_path(environment)
    YAML.load_file terrafile_path(environment)
  else
    puts terrafile_path(environment)
    fail('[*] Terrafile does not exist')
  end
end

def create_modules_directory(environment)
  unless Dir.exist? modules_path(environment)
    puts "[*] Creating Terraform modules directory at '#{modules_path(environment)}'"
    FileUtils.makedirs modules_path(environment)
  end
end

def delete_cached_terraform_modules(environment)
  puts "[*] Deleting cached Terraform modules at '#{modules_path(environment)}'"
  FileUtils.rm_rf modules_path(environment)
end

desc 'Fetch the Terraform modules listed in the Terrafile'
task :get_modules, :environment do |t, args|
  terrafile = read_terrafile(args[:environment])

  create_modules_directory(args[:environment])
  delete_cached_terraform_modules(args[:environment])

  # Keep track of every thread
  threads = {}

  terrafile.each do |module_name, repository_details|
    threads[module_name] = Thread.new do
      source      = repository_details['source']
      version     = repository_details['version']
      destination = File.join(modules_path(args[:environment]), module_name)
      msg         = "Checking out #{version} of #{source}"

      clone_was_ok = system("git clone -b #{version} #{source} #{destination} > /dev/null 2>&1")
      if clone_was_ok
        puts "[*] #{msg}"
      else
        puts "[ERROR] #{msg}"
        exit 1
      end
    end
  end

  # Waint until every thead finish its work
  threads.values.each { |t| t.join }
end

desc 'Remove Terraform modules path'
task :remove_modules, :environment do |t, args|
  terrafile = read_terrafile(args[:environment])
  delete_cached_terraform_modules(args[:environment])
end

