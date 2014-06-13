# plone.pp

class plone::install ( $install_dir         = $plone::params::plone_install_dir,
                       $instances           = { 'client0' => { port => '8080'} },
                       $plone_group         = $plone::params::plone_group,
                       $plone_user          = $plone::params::plone_user,
                       $buildout_user       = $plone::params::plone_buildout_user,
                       $admin_user          = $plone::params::instance_user,
                       $admin_password      = $plone::params::instance_pw,
                       $find_links          = $plone::params::find_links,
                       $custom_extends      = [],
                       $custom_eggs         = [],
		     ) inherits plone::params {

  include plone::zope
 
  # Create plone user and group
  group { $plone_group:
    ensure => present,
  }

  user { $plone_user:
    ensure => present,
    groups => [$plone_group],
    home   => '/bin/false',
    shell  => '/usr/sbin/nologin',
  }

  user { $buildout_user:
    ensure => present,
    groups => [$plone_group],
    home   => '/bin/false',
    shell  => '/bin/bash',
  }

  # Create install directory
  file { $install_dir:
    ensure => directory,
    owner  => $buildout_user,
    group  => $plone_group,
    mode   => '2755',
  }


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

  validate_hash($instances)
  create_resources(plone::instance, $instances, $instance_defaults)

  # install init script
  case $operatingsystem {
    'Ubuntu': {
      concat { "/etc/init/plone.conf":
        owner => 'root', group => 'root', mode => 644,
      }
      concat::fragment { "plone_upstart_header":
        target  => "/etc/init/plone.conf",
        content => template('plone/plone_upstart.conf.erb'),
        order   => '01',
      }
    }
  }

}

