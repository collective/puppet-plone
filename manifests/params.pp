# params.pp

class plone::params {

  #Buildout defaults 
  $buildout_dir       = '/srv/buildout'
  $buildout_cache_dir = 'buildout-cache'
  $buildout_source    = 'http://downloads.buildout.org/2/bootstrap.py'
  $find_links         = [ 'http://dist.plone.org',
                          'http://download.zope.org/ppix/',
                          'http://download.zope.org/distribution/',
                          'http://effbot.org/downloads',
                          'http://effbot.org/downloads',
		          'http://dist.plone.org/release/4.3-latest' ]

  $buildout_user  = 'root'
  $buildout_group = 'root'

  # Plone module defaults
  $default_install_type = 'standalone'
  $default_standalone_instances = { 'client0' => { port => '8080'} }
  $default_zeo_instances = { 'server' => { port => '8100'} }

  # Plone Instances defaults 
  $zeo_client_status    = false
  $inst_readonly_status = false
  $instance_port        = '8080'
  $instance_user        = 'admin'
  $instance_pw          = 'admin'
  $instance_eggs        = [ 'Plone', 'Pillow' ]

  # Zeo server defaults
  $zeo_port = '8100'
  $default_zrs_role = 'disabled'

  #Plone Buildout defaults
  $extends             = ['http://dist.plone.org/release/4.3.3/versions.cfg']
  $plone_user          = 'plone_daemon'
  $plone_group         = 'plone_group'
  $plone_buildout_user = 'plone_buildout'
  $plone_install_dir   = '/srv/plone'
  $plone_versions      = { 'zc.buildout'                   => '>= 2.2.1',
                           'setuptools'                    => '>= 2.2',
                           'ZopeSkel'                      => '2.21.2',
                           'Cheetah'                       => '2.2.1',
                           'Products.DocFinderTab'         => '1.0.5',
                           'buildout.sanitycheck'          => '1.0b1',
                           'collective.recipe.backup'      => '2.17',
                           'plone.recipe.unifiedinstaller' => '4.3.1',
                           'zopeskel.dexterity'            => '1.5.4.1',
                           'zopeskel.diazotheme'           => '1.1',
                         }

  
}
