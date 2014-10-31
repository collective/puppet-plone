# init.pp

class plone ( $install_dir         = $plone::params::plone_install_dir,
              $instances           = {},
              $sites               = {},
              $filestorages        = {},
              $plone_group         = $plone::params::plone_group,
              $plone_gid           = $plone::params::plone_gid,
              $plone_user          = $plone::params::plone_user,
              $plone_uid           = $plone::params::plone_uid,
              $buildout_user       = $plone::params::plone_buildout_user,
              $buildout_uid        = $plone::params::plone_buildout_uid,
              $admin_user          = $plone::params::instance_user,
              $admin_password      = $plone::params::instance_pw,
              $find_links          = $plone::params::find_links,
              $custom_extends      = [],
              $custom_eggs         = [],
              $type                = $plone::params::default_install_type, 
              $create_default_inst = $plone::params::create_default_inst,
	    ) inherits plone::params {

  include plone::zope
 
  # Create plone user and group
  group { $plone_group:
    ensure => present,
    gid    => $plone_gid,
  }

  user { $plone_user:
    ensure => present,
    groups => [$plone_group],
    home   => '/bin/false',
    shell  => '/usr/sbin/nologin',
    uid    => $plone_uid,
  }

  user { $buildout_user:
    ensure => present,
    groups => [$plone_group],
    home   => '/bin/false',
    shell  => '/bin/bash',
    uid    => $buildout_uid,
  }

  # Create install directory
  file { $install_dir:
    ensure => directory,
    owner  => $buildout_user,
    group  => $plone_group,
    mode   => '2755',
  }

  case $type {
    'standalone', 'zeoclient': {
      notify { "Plone $type install.": }

      $instance_defaults = {
        user           => $admin_user,
        password       => $admin_password,
        install_dir    => $install_dir,
        buildout_user  => $buildout_user,
        plone_user     => $plone_user,
        plone_group    => $plone_group,
        find_links     => $find_links,
        custom_eggs    => $custom_eggs,
        custom_extends => $custom_extends
      }
      if ( $instances == {} and $create_default_inst == true ) {
        create_resources( plone::instance, 
                          $plone::params::default_standalone_instances, 
                          $instance_defaults )
      } else {  
        validate_hash($instances)
        create_resources(plone::instance, $instances, $instance_defaults)
      }
    } 
    'zeo': {
      notify { "Plone zeo server install.": }

      $zeo_defaults = {
        install_dir    => $install_dir,
        buildout_user  => $buildout_user,
        plone_user     => $plone_user,
        plone_group    => $plone_group,
        find_links     => $find_links,
      }
      if ( $instances == {} and $create_default_inst == true) {
        create_resources( plone::zeo,
                          $plone::params::default_zeo_instances,
                          $zeo_defaults )
      } else {
        validate_hash($instances)
        create_resources(plone::zeo, $instances, $zeo_defaults)
      }

    }
    default: {
      fail("Install type $type not supported! Supported types are standalone, zeo or zeoclient.")
    }
  }

  # Create plone sites
  validate_hash($sites)
  $default_site_params = { install_dir => $install_dir }
  create_resources(plone::site, $sites, $default_site_params)

  # Create filestorages
  validate_hash($filestorages)
  $default_fs_params = { install_dir => $install_dir }
  create_resources(plone::filestorage, $filestorages, $default_fs_params)


}

