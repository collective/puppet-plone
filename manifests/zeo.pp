# zeo.pp
# requires puppetlabs-stdlib

define plone::zeo ( $port           = $plone::params::zeo_port,
                    $install_dir    = $plone::params::plone_install_dir,
                    $buildout_user  = $plone::params::plone_buildout_user,
                    $plone_user     = $plone::params::plone_user, 
                    $plone_group    = $plone::params::plone_group,
                    $find_links     = $plone::params::find_links,
                    $plone_versions = $plone::params::plone_versions,
                    $zrs_role       = $plone::params::default_zrs_role,
                    $zrs_repl_host  = '',
                    $custom_extends = [],
                    $custom_eggs    = [],
                   ) {

  include plone::params

  #Instantiate buildout and buildout section
  validate_array($custom_extends)
  $extends = concat($plone::params::extends,$custom_extends)
  validate_array($custom_eggs)
  $eggs = concat($plone::params::instance_eggs,$custom_eggs)

  plone::buildout { "zeo-${name}":
    user            => $buildout_user,
    group           => $plone_group,
    buildout_dir    => "${install_dir}",
    buildout_params => { extends              => $extends,
                         buildout-user        => $buildout_user,
                         effective-user       => $plone_user,
                         find-links           => $find_links,
                         eggs                 => $eggs,
                         parts                => [ 'zeoserver',
                                                   'zopepy',
                                                   'backup',
                                                   'precompiler',
                                                 ],
                         allow-hosts          => [ '*.python.org' ],
                         var-dir              => '${buildout:directory}/var',
                         backups-dir          => '${buildout:var-dir}',
                         newest               => 'false',
                         prefer-final         => 'true',
                         extensions           => [ 'buildout.sanitycheck' ],
                         environment-vars     => 'zope_i18n_compile_mo_files true',
                         deprecation-warnings => 'off',
			 verbose-security     => 'off',
                       },
    require         => [ User[$buildout_user],
                         File[$install_dir],
                       ],
  }

  #Create versions section
  plone::buildoutsection { "versions_zeo-$name":
    section_name => "versions",
    cfghash      => $plone_versions,
    buildout_dir => "${install_dir}/zeo-$name",
  }

  #Create zeoserver section
  $zeo_common_config = {  zeo-address    => [ "$port" ],
                          effective-user => '${buildout:effective-user}',
                          var            => "$install_dir/zeo-$name/var",
                          zeo-log        => "$install_dir/zeo-$name/var/log/zeoserver.log",
                       }

  case $zrs_role {
    'primary': {
      validate_re($zrs_repl_host,'\b(?:\d{1,3}\.){3}\d{1,3}\b:\d{1,5}\b',"Invalid ZRS replication host. Must be an IP Socket.")

      $zeo_cfg_header = { recipe         => 'plone.recipe.zeoserver[zrs]',
                          replicate-to   => $zrs_repl_host }
    }
    'secondary': {
      validate_re($zrs_repl_host,'\b(?:\d{1,3}\.){3}\d{1,3}\b:\d{1,5}\b',"Invalid ZRS replication host. Must be an IP Socket.")
      $zeo_cfg_header = { recipe         => 'plone.recipe.zeoserver[zrs]',
                          replicate-from => $zrs_repl_host }
    }
    'disabled': {
      $zeo_cfg_header = { recipe => 'plone.recipe.zeoserver' }
    }
    default: {
      fail ("Unknown ZRS role $zrs_role. Valid ones are primary, secondary or disabled.")
    }
  }  

  plone::buildoutsection { "zeoserver_$name":
        section_name => "zeoserver",
        cfghash      => merge($zeo_cfg_header,$zeo_common_config), 
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

  plone::buildoutsection { "zopepy_zeo-$name":
    section_name => "zopepy",
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

  plone::buildoutsection { "precompiler_zeo-$name":
    section_name => "precompiler",
    cfghash      => { recipe => 'plone.recipe.precompiler',
                      eggs => '${buildout:eggs}',
                      compile-mo-files => 'true',
                      extra-paths => '${buildout:directory}/products',
                    },
    buildout_dir => "${install_dir}/zeo-$name",
  }

  # This recipe builds the backup, restore and snapshotbackup commands.
  # For options see http://pypi.python.org/pypi/collective.recipe.backup

  plone::buildoutsection { "backup_zeo-$name":
    section_name => "backup",
    cfghash      => { recipe => 'collective.recipe.backup',
                      location => '${buildout:backups-dir}/backups',
                      blobbackuplocation => '${buildout:backups-dir}/blobstoragebackups',
                      snapshotlocation => '${buildout:backups-dir}/snapshotbackups',
                      blobsnapshotlocation => '${buildout:backups-dir}/blobstoragesnapshots',
                      datafs => '${buildout:var-dir}/filestorage/Data.fs',
                      blob-storage => '${buildout:var-dir}/blobstorage',
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
