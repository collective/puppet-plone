# params.pp

class plone::params {

  #Buildout defaults 
  $find_links         = ['http://dist.plone.org',
                         'http://download.zope.org/ppix/',
                         'http://download.zope.org/distribution/',
                         'http://effbot.org/downloads',
		         'http://dist.plone.org/release/4.3-latest',
                         'https://github.com/interlegis/collective.recipe.plonesite/tarball/master#egg=collective.recipe.plonesite-1.8.6' ]
  $allow_hosts        = [ '*.python.org',
                          '*.plone.org',
                          'github.com' ]

  # Plone module defaults
  $default_install_type         = 'standalone'
  $default_standalone_instances = { 'client0' => { port => '8080'} }
  $default_zeo_instances        = { 'server' => { port => '8100'} }
  $create_default_inst          = true

  # Plone Instances defaults 
  $zeo_client_status    = false
  $inst_readonly_status = false
  $instance_port        = '8080'
  $instance_user        = 'admin'
  $instance_pw          = 'admin'
  $instance_eggs        = [ 'Plone', 'Pillow' ]
  $enable_tempstorage   = false
  $blobstorage_dir      = '${buildout:directory}/var/blobstorage'
  $zserver_threads      = 1

  # Zeo server defaults
  $zeo_port               = '8100'
  $default_zrs_role       = 'disabled'
  $default_zrs_keep_alive = '60'
  $default_invalid_queue  = '100'
  $zeo_eggs               = [ 'Zope2', 'plone.app.blob', 'tempstorage' ]
  $backups_dir            = '${buildout:var-dir}' 

  # Plone File Storage Defaults
  $filestorage_blobdir       = 'var/blobstorage-%(fs_part_name)s' 
  $filestorage_enable_backup = false

  #Plone Buildout defaults
  $extends             = ['http://dist.plone.org/release/4.3.3/versions.cfg']
  $plone_user          = 'plone_daemon'
  $plone_uid           = '1006'
  $plone_group         = 'plone_group'
  $plone_gid           = '1006'
  $plone_buildout_user = 'plone_buildout'
  $plone_buildout_uid  = '1007'
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
                           'collective.recipe.plonesite'   => '1.8.6',
                         }

  #Plone Site Defaults
  $default_site_id               = 'plone'
  $default_site_replace          = 'false'
  $default_site_container        = '/'
  $default_site_protocol         = 'http'
  $default_site_port             = '80'
  $default_site_use_vhm          = 'true'
  $default_site_language         = 'en'
  $default_site_add_mountpoint   = false
  $default_site_admin_user       = 'admin'
  $default_site_enabled          = 'true'
  $default_site_refresh_only     = 'true'
}
