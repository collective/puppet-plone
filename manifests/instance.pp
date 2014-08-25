# instance.pp
# requires puppetlabs/stdlib
#          interlegis/buildout

define plone::instance ( $port               = $plone::params::instance_port,
                         $user               = $plone::params::instance_user,
                         $password           = $plone::params::instance_pw,
                         $install_dir        = $plone::params::plone_install_dir,
                         $buildout_user      = $plone::params::plone_buildout_user,
                         $plone_user         = $plone::params::plone_user, 
                         $plone_group        = $plone::params::plone_group,
                         $find_links         = $plone::params::find_links,
                         $plone_versions     = $plone::params::plone_versions,
                         $read_only          = $plone::params::inst_readonly_status,
                         $zeo_client         = $plone::params::zeo_client_status,
                         $enable_tempstorage = $plone::params::enable_tempstorage,
                         $blobstorage_dir    = $plone::params::blobstorage_dir,
                         $zeo_address        = '', 
                         $custom_eggs        = [],
                         $custom_extends     = [],
                         $custom_bout_params = {},
                         $custom_params      = {},
                         $sites              = {},
                       ) {

  include plone::params

  #Instantiate buildout and buildout section
  validate_array($custom_extends)
  
  $bout_params = { extends              => concat($plone::params::extends,$custom_extends),
                   buildout-user        => $buildout_user,
                   effective-user       => $plone_user,
                   find-links           => $find_links,
                   allow-hosts          => $plone::params::allow_hosts,
                   var-dir              => '${buildout:directory}/var',
                   backups-dir          => '${buildout:var-dir}',
                   newest               => 'false',
                   prefer-final         => 'true',
                   extensions           => [ 'buildout.sanitycheck' ],
                   environment-vars     => 'zope_i18n_compile_mo_files true',
                   deprecation-warnings => 'off',
                   verbose-security     => 'off',
                   eggs-directory       => "${install_dir}/buildout-cache/eggs",
                   download-cache       => "${install_dir}/buildout-cache/downloads",
                 }

  buildout::env { $name:
    user    => $buildout_user,
    group   => $plone_group,
    dir     => "${install_dir}",
    params  => merge($bout_params, $custom_bout_params),
    require => [ User[$buildout_user],
                 File[$install_dir],
               ],
  }

  #Create versions section

  buildout::section { "versions_$name":
    section_name => "versions",
    cfghash      => $plone_versions,
    buildout_dir => "${install_dir}/$name",
  }

  #Create instance section
  validate_array($custom_eggs)
  $eggs = concat($plone::params::instance_eggs,$custom_eggs)

  $inst_common_conf_h = { recipe               => 'plone.recipe.zope2instance',
                          http-address         => "$port",
                          read-only            => "$read_only",
                          user                 => "$user:$password",
                          effective-user       => '${buildout:effective-user}',
                          eggs                 => $eggs,
                          var                  => "$install_dir/$name/var",
                          event-log            => "$install_dir/$name/var/log/event.log",
                          z2-log               => "$install_dir/$name/var/log/Z2.log",
                          event-log-max-size   => '5 MB',
                          event-log-old-files  => '5',
                          access-log-max-size  => '20 MB',
                          access-log-old-files => '5',
                          debug-mode           => 'off',
                          verbose-security     => '${buildout:verbose-security}',
                          deprecation-warnings => '${buildout:deprecation-warnings}',
                          blob-storage         => $blobstorage_dir,
                        }

  $inst_common_config = merge($inst_common_conf_h,$custom_params)

  if $zeo_client == true {
    validate_re($zeo_address,'\b(?:\d{1,3}\.){3}\d{1,3}\b:\d{1,5}\b',"Invalid ZEO server host. Must be an IP Socket.")

    $inst_cfg_header_h = { zeo-client       => 'true',
                           shared-blob      => 'on',
                           http-fast-listen => 'off',
                           zeo-address      => "$zeo_address",
                         }
    $tempstorage_cfg = { zodb-temporary-storage =>
                          [ '<zodb_db temporary>',
                            '  mount-point /temp_folder',
                            '  cache-size 10000',
                            '  container-class Products.TemporaryFolder.TemporaryContainer',
                            '  <zeoclient>',
                            '    server ${instance:zeo-address}',
                            '    storage temp',
                            '    var ${buildout:directory}/var/filestorage',
                            '    cache-size 1024MB',
                            '  </zeoclient>',
                            '</zodb_db>' ]
                       }
    if $enable_tempstorage {
      $inst_cfg_header = merge($inst_cfg_header_h,$tempstorage_cfg)
    } else {
      $inst_cfg_header = $inst_cfg_header_h
    }
  } else {
    $inst_cfg_header = { }
  }

  buildout::part { "instance_$name":
    part_name    => "instance",
    cfghash      => merge($inst_cfg_header,$inst_common_config),
    buildout_dir => "${install_dir}/$name",
  }
  
  file { [ "$install_dir/$name/var", 
           "$install_dir/$name/var/log",
           "$install_dir/$name/var/filestorage",
           "$install_dir/$name/var/blobstorage" ]:
    ensure  => directory,
    mode    => 2770,
    group   => "$plone_group",
    require => Exec["run_buildout_$name"], 
  }

  # installs a zopepy python interpreter that runs with your
  # full Zope environment

  buildout::part { "zopepy_$name":
    part_name    => "zopepy",
    cfghash      => { recipe => 'zc.recipe.egg',
                      eggs => '${instance:eggs}',
                      interpreter => 'zopepy',
                      scripts => 'zopepy',
                    },
    buildout_dir => "${install_dir}/$name",
  }

  # This recipe is used in production installs to compile
  # .py and .po files so that the daemon doesn't try to do it.
  # For options see http://pypi.python.org/pypi/plone.recipe.precompiler

  buildout::part { "precompiler_$name":
    part_name    => "precompiler",
    cfghash      => { recipe => 'plone.recipe.precompiler',
                      eggs => '${instance:eggs}',
                      compile-mo-files => 'true',
                      extra-paths => '${buildout:directory}/products',
                    },
    buildout_dir => "${install_dir}/$name",
  }

  # This recipe installs the plonectl script and a few other convenience items.
  # For options see http://pypi.python.org/pypi/plone.recipe.unifiedinstaller

  buildout::part { "unifiedinstaller_$name":
    part_name    => "unifiedinstaller",
    cfghash      => { recipe => 'plone.recipe.unifiedinstaller',
                      user => '${instance:user}',
                      effective-user => '${buildout:effective-user}',
                      buildout-user => '${buildout:buildout-user}',
                      need-sudo => 'yes'
                    },
    buildout_dir => "${install_dir}/$name",
  }

  # Init script
  case $operatingsystem {
    'Ubuntu': {
      file { "/etc/init/plone-$name.conf":
        owner => 'root', group => 'root', mode => 644,
        content => template('plone/plone_upstart.conf.erb'),
      }
      service { "plone-$name":
        enable    => true,
        ensure    => running,
        provider  => upstart,
        subscribe => Exec["run_buildout_$name"],
        require   => File["/etc/init/plone-$name.conf"],
      }
    }
   default: {
     notify { "Puppet will not manage Plone $name service, since this operating system is not supported": } 
   }
  }

}
