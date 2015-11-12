# zeo.pp
# requires puppetlabs-stdlib

define plone::zeo ( $port                   = $plone::params::zeo_port,
                    $install_dir            = $plone::params::plone_install_dir,
                    $buildout_user          = $plone::params::plone_buildout_user,
                    $plone_user             = $plone::params::plone_user,
                    $plone_group            = $plone::params::plone_group,
                    $find_links             = $plone::params::find_links,
                    $plone_versions         = $plone::params::plone_versions,
                    $blobstorage_dir        = $plone::params::blobstorage_dir,
                    $backups_dir            = $plone::params::backups_dir,
                    $backups_keep           = $plone::params::backups_keep,
                    $backups_keep_blob_days = $plone::params::backups_keep_blob_days,
                    $zrs_role               = $plone::params::default_zrs_role,
                    $zrs_keep_alive         = $plone::params::default_zrs_keep_alive,
                    $zrs_repl_host          = '',
                    $invalid_queue          = $plone::params::default_invalid_queue,
                    $pack_days              = $plone::params::pack_days,
                    $custom_extends         = [],
                    $custom_eggs            = [],
                    $bout_cache_file        = undef,
                  ) {

  include plone::params

  #Instantiate buildout and buildout section
  validate_array($custom_extends)
  $extends = concat($plone::params::extends,$custom_extends)
  validate_array($custom_eggs)
  $eggs = concat($plone::params::zeo_eggs,$custom_eggs)

  buildout::env { "zeo-${name}":
    user            => $buildout_user,
    group           => $plone_group,
    dir             => "${install_dir}",
    cachefile       => $bout_cache_file,
    params          => {  extends              => $extends,
                          buildout-user        => $buildout_user,
                          effective-user       => $plone_user,
                          eggs                 => $eggs,
                          find-links           => $find_links,
                          allow-hosts          => $plone::params::allow_hosts,
                          var-dir              => '${buildout:directory}/var',
                          backups-dir          => $backups_dir,
                          newest               => 'false',
                          prefer-final         => 'true',
                          extensions           => [ 'buildout.sanitycheck' ],
                          environment-vars     => 'zope_i18n_compile_mo_files true',
                          deprecation-warnings => 'off',
                          verbose-security     => 'off',
                          eggs-directory       => "${install_dir}/buildout-cache/eggs",
                          download-cache       => "${install_dir}/buildout-cache/downloads",
                        },
    require         =>  [ User[$buildout_user],
                          File[$install_dir],
                        ],
  }

  #Create versions section
  buildout::section { "versions_zeo-$name":
    section_name => "versions",
    cfghash      => $plone_versions,
    buildout_dir => "${install_dir}/zeo-$name",
  }

  #Create zeoserver section
  $zeo_common_config = {  zeo-address         => [ "$port" ],
                          eggs                => $eggs,
                          effective-user      => '${buildout:effective-user}',
                          var                 => "$install_dir/zeo-$name/var",
                          blob-storage        => $blobstorage_dir,
                          zeo-log             => "$install_dir/zeo-$name/var/log/zeoserver.log",
                          zeo-conf-additional => [  '%import tempstorage',
                                                    '<temporarystorage temp>',
                                                    '  name temporary storage for sessioning',
                                                    '</temporarystorage>' ],
                          invalidation-queue-size  => $invalid_queue,
                          pack-days                => $pack_days,
                        }

  case $zrs_role {
    'primary': {
      validate_re($zrs_repl_host,'\b(?:\d{1,3}\.){3}\d{1,3}\b:\d{1,5}\b',"Invalid ZRS replication host. Must be an IP Socket.")

      $zeo_cfg_header = { recipe           => 'plone.recipe.zeoserver[zrs]',
                          replicate-to     => $zrs_repl_host,
                          keep-alive-delay => $zrs_keep_alive,
                          eggs             => concat($eggs,['plone.recipe.zeoserver[zrs]']),
                        }
    }
    'secondary': {
      validate_re($zrs_repl_host,'\b(?:\d{1,3}\.){3}\d{1,3}\b:\d{1,5}\b',"Invalid ZRS replication host. Must be an IP Socket.")
      $zeo_cfg_header = { recipe           => 'plone.recipe.zeoserver[zrs]',
                          replicate-from   => $zrs_repl_host,
                          keep-alive-delay => $zrs_keep_alive,
                          eggs             => concat($eggs,['plone.recipe.zeoserver[zrs]']),
                        }
    }
    'disabled': {
      $zeo_cfg_header = { recipe => 'plone.recipe.zeoserver', 
                          eggs => concat($eggs,['plone.recipe.zeoserver']),
                        }
    }
    default: {
      fail ("Unknown ZRS role $zrs_role. Valid ones are primary, secondary or disabled.")
    }
  }  

  buildout::part { "zeoserver_$name":
        part_name    => "zeoserver",
        cfghash      => merge($zeo_common_config,$zeo_cfg_header), 
        buildout_dir => "${install_dir}/zeo-$name",
  }

  file { [ "$install_dir/zeo-$name/var", 
           "$install_dir/zeo-$name/var/log",
           "$install_dir/zeo-$name/var/filestorage",
           "$install_dir/zeo-$name/var/blobstorage" ]:
    ensure  => directory,
    mode    => 2770,
    group   => "$plone_group",
    require => Exec["run_buildout_zeo-$name"], 
  }

  # installs a zopepy python interpreter that runs with your
  # full Zope environment

  buildout::part { "zopepy_zeo-$name":
    part_name    => "zopepy",
    cfghash      => { recipe => 'zc.recipe.egg',
                      eggs => '${buildout:eggs}',
                      interpreter => 'zopepy',
                      scripts => 'zopepy',
                    },
    buildout_dir => "${install_dir}/zeo-$name",
  }

  # This recipe is used in production installs to compile
  # .py and .po files so that the daemon doesn't try to do it.
  # For options see http://pypi.python.org/pypi/plone.recipe.precompiler

  buildout::part { "precompiler_zeo-$name":
    part_name    => "precompiler",
    cfghash      => { recipe => 'plone.recipe.precompiler',
                      eggs => '${buildout:eggs}',
                      compile-mo-files => 'true',
                      extra-paths => '${buildout:directory}/products',
                    },
    buildout_dir => "${install_dir}/zeo-$name",
  }

  # This recipe builds the backup, restore and snapshotbackup commands.
  # For options see http://pypi.python.org/pypi/collective.recipe.backup

  buildout::part { "backup_zeo-$name":
    part_name    => "backup",
    cfghash      => { recipe               => 'collective.recipe.backup',
                      location             => '${buildout:backups-dir}/backups',
                      blobbackuplocation   => '${buildout:backups-dir}/blobstoragebackups',
                      snapshotlocation     => '${buildout:backups-dir}/snapshotbackups',
                      blobsnapshotlocation => '${buildout:backups-dir}/blobstoragesnapshots',
                      datafs               => '${buildout:var-dir}/filestorage/Data.fs',
                      blob-storage         => $blobstorage_dir,
                      keep                 => $backups_keep,
                      keep_blob_days       => $backups_keep_blob_days,
                    },
    buildout_dir => "${install_dir}/zeo-$name",
  }



  # Init script
  case $operatingsystem {
    'Ubuntu': {
      file { "/etc/init/zeo-$name.conf":
        owner => 'root', group => 'root', mode => 644,
        content => template('plone/zeo_upstart.conf.erb'),
      }
      service { "zeo-$name":
        enable    => true,
        ensure    => running,
        provider  => upstart,
        subscribe => Exec["run_buildout_zeo-$name"],
        require   => File["/etc/init/zeo-$name.conf"],
      }
    }
   default: {
     notify { "Puppet will not manage Plone $name service, since this operating system is not supported": } 
   }
  }

}
