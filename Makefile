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

install:
	groupadd allura
	useradd -g allura allura
	passwd allura
	usermod -aG sudo allura
	mkdir -p  /home/allura/allura-install
	cp ./* /home/allura/allura-install/ 
	chown -R allura:allura /home/allura
	chown -R allura:allura .
	cd /home/allura/allura-install
	make all

install-apt-packages:
	apt-get update
	apt-get install -y \
		git-core default-jre-headless python-dev libssl-dev libldap2-dev \
		libsasl2-dev libjpeg8-dev zlib1g-dev subversion python-svn \
		libapache2-mod-wsgi python-pip unzip

install-mongodb:
	mkdir -p /data/db
	sudo chown `id -u` /data/db
	apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
	echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' \
		| tee /etc/apt/sources.list.d/mongodb.list
	apt-get update
	apt-get install -y mongodb-org
	service mongod restart
	sleep 5
	service mongod status

create-directories:
	mkdir -p /var/log/allura
	mkdir -p /var/www/allura
	mkdir -p ~/src
	mkdir -p /opt

set-permissions:
	chown -R allura:allura /var/log/allura
	chown -R allura:allura /var/www/allura
	chown -R allura:allura ~/src

install-allura-python:
	pip install virtualenv
	sudo -u allura virtualenv /home/allura/env-allura
	sudo -u allura sh -c 'cd / && git clone https://git-wip-us.apache.org/repos/asf/allura.git /home/allura/src/allura'
	sudo -H -u allura sh -c 'cd / &&  /home/allura/env-allura/bin/pip install -r /home/allura/src/allura/requirements.txt'
	ln -s /usr/lib/python2.7/dist-packages/pysvn /home/allura/env-allura/lib/python2.7/site-packages/
	sudo -u allura sh -c '\
		cd /home/allura/src/allura && \
		. /home/allura/env-allura/bin/activate && \
		./rebuild-all.bash'

install-solr:	
	cd /home/allura/src && \
		wget -nv http://archive.apache.org/dist/lucene/solr/5.3.1/solr-5.3.1.tgz && \
		tar xvf solr-5.3.1.tgz solr-5.3.1/bin/install_solr_service.sh --strip-components=2 && \
		sudo ./install_solr_service.sh solr-5.3.1.tgz
	cd /home/allura/src/allura && \
		sudo -H -u solr bash -c 'cp -R solr_config/allura/ /var/solr/data/' && \
		sudo service solr restart

create-git-directory:
	sudo mkdir -p /srv/git && \
		sudo chown allura /srv/git && \
		sudo chmod 775 /srv/git

initialize-allura-taskd:
	cd /home/allura/src/allura/Allura && \
		nohup paster taskd development.ini > /var/log/allura/taskd.log 2>&1 &
	make npm-build

npm-build:
	sudo -u allura sh -c '\
		cd /home/allura/src/allura && \
		. /home/allura/env-allura/bin/activate && \
		curl --silent --location https://deb.nodesource.com/setup_4.x | sudo bash - && \
		sudo apt-get install nodejs && \
		cd /home/allura/src/allura && \
		npm install && \
		npm run build'

initialize-allura-data:
	. /home/allura/env-allura/bin/activate && \
		cd /home/allura/src/allura/Allura && \
		ALLURA_TEST_DATA=False paster setup-app development.ini

copy-files:
	sudo cp allura.wsgi /var/www/allura/allura.wsgi
	sudo mkdir -p /etc/apache2/sites-enabled/
	sudo cp allura.conf /etc/apache2/sites-enabled/allura.conf

update-hosts:
	echo -e "\n127.0.0.1 allura.dev" | tee -a /etc/hosts

reload-apache:
	service apache2 reload
