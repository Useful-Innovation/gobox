all:
	cp config/resources/Vagrantfile ../
	cp -n config/resources/gobox.yaml ../
	mkdir -p provisioners
	cp -n config/resources/custom_provisioners/* provisioners/
