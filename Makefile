all:
	cp resources/Vagrantfile ../../
	cp -n resources/gobox.yaml ../../

	mkdir -p ../provisioners
	cp -n resources/custom_provisioners/* ../provisioners/


	grep -q -F '!.vagrant' ~/.bashrc || echo '!.vagrant' >> ../../.gitignore
	grep -q -F '.vagrant/machines' ~/.bashrc || echo '.vagrant/machines' >> ../../.gitignore
