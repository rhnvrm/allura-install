all:
	make install-apt-packages
	make install-mongodb
	make create-directories
	make set-permissions
	make install-allura-python
	make install-solr
	make create-git-directory
	make initialize-allura-taskd
	make initialize-allura-data
	make copy-files
	make set-permissions
	make update-hosts
	make reload-apache

install-apt-packages:
	apt-get update
	apt-get install -y \
		git-core default-jre-headless python-dev libssl-dev libldap2-dev \
		libsasl2-dev libjpeg8-dev zlib1g-dev subversion python-svn \
		libapache2-mod-wsgi python-pip

install-mongodb:
	apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
	echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' \
		| tee /etc/apt/sources.list.d/mongodb.list
	apt-get update
	apt-get install -y mongodb-org
	echo "smallfiles = true" | tee -a /etc/mongod.conf
	service mongod restart
	sleep 5
	service mongod status

create-directories:
	mkdir -p /var/log/allura
	mkdir -p /var/www/allura
	mkdir -p ~/src

set-permissions:
	chown -R allura:allura /var/log/allura
	chown -R allura:allura /var/www/allura
	chown -R allura:allura ~/src

install-allura-python:
	pip install virtualenv
	sudo -u allura virtualenv ~/env-allura
	sudo -u allura git clone https://git-wip-us.apache.org/repos/asf/allura.git ~/src/allura
	sudo -u allura ~/env-allura/bin/pip install -r ~/src/allura/requirements.txt
	ln -s /usr/lib/python2.7/dist-packages/pysvn ~/env-allura/lib/python2.7/site-packages/
	sudo -u allura sh -c '\
		cd ~/src/allura && \
		. ~/env-allura/bin/activate && \
		./rebuild-all.bash'

install-solr:	
	cd ~/src && \
		mkdir /opt && \
		wget -nv http://archive.apache.org/dist/lucene/solr/5.3.1/solr-5.3.1.tgz && \
		tar xvf solr-5.3.1.tgz solr-5.3.1/bin/install_solr_service.sh --strip-components=2 && \
		sudo ./install_solr_service.sh solr-5.3.1.tgz
	cd ~/src/allura && \
		sudo -H -u solr bash -c 'cp -R solr_config/allura/ /var/solr/data/' && \
		sudo service solr start

create-git-directory:
	mkdir -p /srv/git && \
		chown allura /srv/git && \
		chmod 775 /srv/git

initialize-allura-taskd:
	cd ~/src/allura/Allura && \
		nohup paster taskd development.ini > /var/log/allura/taskd.log 2>&1 &

initialize-allura-data:
	. ~/env-allura/bin/activate && \
		cd ~/src/allura/Allura && \
		ALLURA_TEST_DATA=False paster setup-app development.ini

copy-files:
	sudo cp allura.wsgi /var/www/allura/allura.wsgi
	sudo cp allura.conf /etc/apache2/sites-enabled/allura.conf

update-hosts:
	echo -e "\n127.0.0.1 allura.dev" | tee -a /etc/hosts

reload-apache:
	service apache2 reload
