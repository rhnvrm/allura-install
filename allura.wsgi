import logging.config
from paste.deploy import loadapp


configuration_path = '/home/allura/src/allura/Allura/development.ini'
logging.config.fileConfig(configuration_path)
application = loadapp('config:{}'.format(configuration_path))