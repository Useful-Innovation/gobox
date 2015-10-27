# -*- mode: ruby -*-

require 'yaml'
require 'fileutils'

# Used to generate ip suffix from projectname.
def numericHash(string,length=255)
  hash = 0
  string.each_byte { |b|
    hash += b;
    hash += (hash << 10);
    hash ^= (hash >> 6);
  }

  hash += (hash << 3);
  hash ^= (hash >> 11);
  hash += (hash << 15);

  return hash % length
end

# Check that vagrant-hostsupdater is installed
if !Vagrant.has_plugin?("vagrant-hostsupdater")
  puts "Please run 'vagrant plugin install vagrant-hostsupdater' to install vagrant-hostsupdater"
  exit
end

# Set paths
configDir       = File.expand_path(".vagrant/config")
projectDir      = Dir.pwd
projectName     = File.basename(projectDir)

# Defaults
defaults = {
  "machine"   => {
    "box"       => "ubuntu/trusty64",
    "memory"    => 1024,
    "hostname"  => projectName
  },
  "folders"   => {"/home/vagrant/#{projectName}" => projectDir},
  "sites"     => {"/home/vagrant/#{projectName}" => projectName},
  "provisioners" => {},
  "versions"  => {
    "apache"    => "2.4.*",
    "php"       => "5.5.*",
    "mysql"     => "5.5.*",
  }
}

# Read config from grunt and set defaults
box = YAML.load_file('gobox.yaml')
box['machine']    =   defaults["machine"].merge!(box['machine'] || {})
box['folders']    ||= defaults["folders"]
box['sites']      ||= defaults["sites"]
box['provisioners']  ||= defaults["provisioners"]
box['versions']   =   defaults["versions"].merge!(box['versions'] || {})

# Link vagrant map
box['folders']['/home/vagrant/config'] = configDir

# Create bash file with project variables
File.open("#{configDir}/config.bash", 'w+') do |f|
  box['versions'].each do |k, v|
    f.write("VAGRANT_#{k.upcase}_VERSION=\"#{v}\"\n")
  end
end

# Create vhosts files
all_vhosts = []
template = File.read("#{configDir}/vhost.template")

# Create dir if not exists
FileUtils.mkdir_p "#{configDir}/vhosts/"
# Remove old vhosts
Dir.glob("#{configDir}/vhosts/*") do |f| File.delete(f) end
# Create new ones
box['sites'].each do |target,hostnames|
  hostnames = [*hostnames]
  all_vhosts.push(*hostnames)

  primary = hostnames.shift
  vhost   = template.gsub("__WEBROOT__", target)
                    .gsub("__PRIMARY__",primary)
                    .gsub("__ALIASES__",hostnames.join(' '))

  File.open("#{configDir}/vhosts/#{primary}.conf", "w+") do |f| f.write(vhost) end
end

Vagrant.configure(2) do |config|

  # Set box. Default to trusty(Ubuntu Server 14.04 LTS)
  config.vm.box = box['machine']["box"]

  # Set IP for this machine or create a numeric hash from hostname
  config.vm.network "private_network",
    ip: box['machine']["ip"] || "192.168.200.#{numericHash(box['machine']["hostname"])}"

  # Set machine hostname
  config.vm.hostname = box['machine']["hostname"]

  # Use hosts ssh agent
  config.ssh.forward_agent = true

  # Push dirs as aliases to hostsupdater
  config.hostsupdater.aliases = all_vhosts

  # VM configuration
  config.vm.provider "virtualbox" do |vb|
    # Customize the amount of memory on the VM:
    vb.memory = box['machine']["memory"]
  end

  # Synced folders
  box['folders'].each do |dest,src|
    config.vm.synced_folder File.expand_path(src), dest,
      :mount_options => ["dmode=777","fmode=666"]
  end

  # Provisioners

  # As root, on provision
  config.vm.provision "shell",
    name:         "root_provision",
    path:         "#{configDir}/provisioners/root_provision.sh"

  [*box['provisioners']['provision_root']].each do |command|
    config.vm.provision "shell",
      name:       "root_provision_custom",
      inline:     command
  end

  # As root, always
  config.vm.provision "shell",
    name:         "root_always",
    path:         "#{configDir}/provisioners/root_always.sh",
    run:          "always"

  [*box['provisioners']['always_root']].each do |command|
    config.vm.provision "shell",
      name:       "root_always_custom",
      inline:     command,
      run:        "always"
  end

  # As user, on provision
  config.vm.provision "shell",
    name:         "user_provision",
    path:         "#{configDir}/provisioners/user_provision.sh",
    privileged:   false

  [*box['provisioners']['provisioners']].each do |command|
    config.vm.provision "shell",
      name:       "user_provision_custom",
      inline:     command,
      privileged: false
  end

  # As user, always
  config.vm.provision "shell",
    name:         "user_always",
    path:         "#{configDir}/provisioners/user_always.sh",
    run:          "always",
    privileged:   false

  [*box['provisioners']['always']].each do |command|
    config.vm.provision "shell",
      name:       "user_always_custom",
      inline:     command,
      run:        "always",
      privileged: false
  end
end