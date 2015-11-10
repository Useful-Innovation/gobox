all:
	cp resources/Vagrantfile ../../
	cp -n resources/gobox.yaml ../../

	mkdir -p ../provisioners
	cp -n resources/custom_provisioners/* ../provisioners/

	grep -q -F '/.vagrant/machines' ../../.gitignore || echo '\n/.vagrant/machines' >> ../../.gitignore
