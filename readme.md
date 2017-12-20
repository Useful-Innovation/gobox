# gobox
Easy vagrant. Configure box in gobox.yaml. Vhosts will be created and hosts file will be updated automagically.

## Installation
From your project folder, run:

```
git submodule add -b xenial64lamp7 git@github.com:gobrave/gobox.git .vagrant/gobox && make -C .vagrant/gobox
```

A Vagrantfile and a sample gobox.yaml will be created.

## Sample `gobox.yaml`

`projectName` = Base name of project folder.

```yaml
---
machine:                          # all or some can be omitted
    box:        gobrave/xenial64lamp7   # default, can be omitted
    memory:     1024              # default, can be omitted
    ip:         192.168.13.37     # can be omitted, defaults to 192.168.200.{hashed projectName}
    hostname:   MYBOX             # can be omitted, defaults to project directory name
folders:                          # object of target => source, defaults to /home/vagrant/{projectName} => ./
    /home/vagrant/foo: foo
    /home/vagrant/bar: bar
sites:                            # object of target => alias/-es, defaults to /home/vagrant/{projectName} => {projectName}
    /home/vagrant/foo:
        -   foo.local
        -   www.foo.local
    /home/vagrant/bar: api.foo.local
databases:                        # str/array, can be omitted, defaults to one database named {projectName}
    - foo
provisioners:                     # Inline provision commands. all or some can be omitted
    always:                       # array, will run every 'up' as user
    - "do stuff"
    always_root:                  # array, will run every 'up' as root
    - "do stuff"
    provision:                    # array, will run on first 'up' or explicit provision as user
    - "do stuff"
    provision_root:               # array, will run on first 'up' or explicit provision as root
    - "do stuff"
```

## Provisioning
Custom(project specific) provision bash scripts can be found in `.vagrant/provisioners`.
