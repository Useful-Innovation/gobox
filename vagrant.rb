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
goboxDir = File.dirname(__FILE__)
mountDir = goboxDir

tempDir   = File.expand_path("#{goboxDir}/temp")
vhostsDir = File.expand_path("#{goboxDir}/temp/vhosts")

# Create paths if not exists
FileUtils.mkdir_p "#{tempDir}"
FileUtils.mkdir_p "#{vhostsDir}"

template  = File.read("#{goboxDir}/resources/vhost.template")

## Mac
if RUBY_PLATFORM == 'x86_64-darwin13'
  ## Catalina NFS mount base
  if %x('uname' '-r').split('.').first == '19'
    mountDir = "/System/Volumes/Data#{mountDir}"
  end
end

projectMountDir = File.expand_path("#{mountDir}/../..")

projectDir  = File.expand_path("#{goboxDir}/../..")
vagrantDir  = File.expand_path("#{goboxDir}/..")
projectName = File.basename(projectDir)

# Defaults
defaults = {
  "machine"   => {
    "box"       => "gobrave/xenial64lamp7",
    "memory"    => 1024,
    "hostname"  => projectName
  },
  "folders"   => {"/home/vagrant/#{projectName}" => projectMountDir},
  "sites"     => {"/home/vagrant/#{projectName}" => projectName},
  "databases" => projectName,
  "provisioners" => {},
}

# Read config and set defaults
if File.file?("#{projectDir}/gobox.yaml")
  box = YAML.load_file("#{projectDir}/gobox.yaml")
  if box.nil?
    box = defaults
  else
    box['machine']        = defaults["machine"].merge!(box['machine'] || {})
    box['folders']      ||= defaults["folders"]
    box['sites']        ||= defaults["sites"]
    box['provisioners'] ||= defaults["provisioners"]
    box['databases']    ||= defaults["databases"]
  end
else
  box = defaults
end

# Link vagrant map
box['folders']['/home/vagrant/.gobox'] = mountDir

# Create bash file with project variables
File.open("#{tempDir}/config.bash", 'w+') do |f|
  f.write("VAGRANT_DATABASES=(#{[*box['databases']].join(' ')})\n")
end

# Create vhosts files
all_vhosts = []

# Remove old vhosts
Dir.glob("#{vhostsDir}/*") do |f| File.delete(f) end
# Create new ones
box['sites'].each do |target,hostnames|
  hostnames = [*hostnames]
  all_vhosts.push(*hostnames)

  primary = hostnames.shift
  vhost   = template.gsub("__WEBROOT__", target)
                    .gsub("__PRIMARY__",primary)
                    .gsub("__ALIASES__",hostnames.join(' '))

  File.open("#{vhostsDir}/#{primary}.conf", "w+") do |f| f.write(vhost) end
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
    # vb.memory = box['machine']["memory"]

    host = RbConfig::CONFIG['host_os']

    # Give VM 1/4 system memory
    if host =~ /darwin/
      # sysctl returns Bytes and we need to convert to MB
      mem = `sysctl -n hw.memsize`.to_i / 1024
    elsif host =~ /linux/
      # meminfo shows KB and we need to convert to MB
      mem = `grep 'MemTotal' /proc/meminfo | sed -e 's/MemTotal://' -e 's/ kB//'`.to_i
    elsif host =~ /mswin|mingw|cygwin/
      # Windows code via https://github.com/rdsubhas/vagrant-faster
      mem = `wmic computersystem Get TotalPhysicalMemory`.split[1].to_i / 1024
    end

    mem = mem / 1024 / 4
    vb.customize ["modifyvm", :id, "--memory", mem]


    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end

  # Synced folders
  box['folders'].each do |dest,src|
    config.vm.synced_folder File.expand_path(src), dest,
      :mount_options => ['nolock,vers=3,udp,noatime,actimeo=1'],
      :nfs => true
  end

  # Provisioners

  # As root, on provision
  config.vm.provision "shell",
    name:         "root_provision",
    path:         "#{goboxDir}/provisioners/root_provision.sh"

  if File.file?("#{vagrantDir}/provisioners/root_provision.sh")
    config.vm.provision "shell",
      name:         "custom_root_provision",
      path:         "#{vagrantDir}/provisioners/root_provision.sh"
  end

  [*box['provisioners']['provision_root']].each do |command|
    config.vm.provision "shell",
      name:       "custom_root_provision_inline",
      inline:     command
  end

  # As root, always
  config.vm.provision "shell",
    name:         "root_always",
    path:         "#{goboxDir}/provisioners/root_always.sh",
    run:          "always"

  if File.file?("#{vagrantDir}/provisioners/root_always.sh")
    config.vm.provision "shell",
      name:         "custom_root_always",
      path:         "#{vagrantDir}/provisioners/root_always.sh",
      run:          "always"
  end

  [*box['provisioners']['always_root']].each do |command|
    config.vm.provision "shell",
      name:       "custom_root_always_inline",
      inline:     command,
      run:        "always"
  end

  # As user, on provision
  config.vm.provision "shell",
    name:         "user_provision",
    path:         "#{goboxDir}/provisioners/user_provision.sh",
    privileged:   false

  if File.file?("#{vagrantDir}/provisioners/user_provision.sh")
    config.vm.provision "shell",
      name:         "custom_user_provision",
      path:         "#{vagrantDir}/provisioners/user_provision.sh",
      privileged:   false
  end

  [*box['provisioners']['provision']].each do |command|
    config.vm.provision "shell",
      name:       "custom_user_provision_inline",
      inline:     command,
      privileged: false
  end

  # As user, always
  config.vm.provision "shell",
    name:         "user_always",
    path:         "#{goboxDir}/provisioners/user_always.sh",
    run:          "always",
    privileged:   false

  if File.file?("#{vagrantDir}/provisioners/user_always.sh")
    config.vm.provision "shell",
      name:         "custom_user_always",
      path:         "#{vagrantDir}/provisioners/user_always.sh",
      run:          "always",
      privileged:   false
  end

  [*box['provisioners']['always']].each do |command|
    config.vm.provision "shell",
      name:       "custom_user_always_inline",
      inline:     command,
      run:        "always",
      privileged: false
  end
end
