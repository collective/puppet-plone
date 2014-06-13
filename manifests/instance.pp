# instance.pp
# requires puppetlabs-stdlib

define plone::instance ( $port           = $plone::params::instance_port,
                         $user           = $plone::params::instance_user,
                         $password       = $plone::params::instance_pw,
                         $install_dir    = $plone::params::plone_install_dir,
                         $buildout_user  = $plone::params::plone_buildout_user,
                         $plone_user     = $plone::params::plone_user, 
                         $plone_group    = $plone::params::plone_group,
                         $find_links     = $plone::params::find_links,
                         $plone_versions = $plone::params::plone_versions, 
                         $custom_eggs    = [],
                         $custom_extends = [],
                       ) {

  include plone::params

  #Instantiate buildout and buildout section
  validate_array($custom_extends)
  $extends = concat($plone::params::extends,$custom_extends)

  plone::buildout { $name:
    user            => $buildout_user,
    group           => $plone_group,
    buildout_dir    => "${install_dir}",
    buildout_params => { extends              => $extends,
                         buildout-user        => $buildout_user,
                         effective-user       => $plone_user,
                         find-links           => $find_links,
                         parts                => [ 'instance',
                                                   'zopepy',
                                                   'unifiedinstaller',
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

  plone::buildoutsection { "versions_$name":
    section_name => "versions",
    cfghash      => $plone_versions,
    buildout_dir => "${install_dir}/$name",
  }

  #Create instance section
  validate_array($custom_eggs)
  $eggs = concat($plone::params::instance_eggs,$custom_eggs)

  plone::buildoutsection { "instance_$name":
    section_name => "instance",
    cfghash      => { recipe => [ 'plone.recipe.zope2instance' ],
                      http-address => [ "$port" ],
                      user => [ "$user:$password" ],
                      effective-user => '${buildout:effective-user}',
                      eggs => $eggs,
                      var  => "$install_dir/$name/var",
                      event-log => "$install_dir/$name/var/log/event.log",
                      z2-log    => "$install_dir/$name/var/log/Z2.log",
                      event-log-max-size => '5 MB',
                      event-log-old-files => '5',
                      access-log-max-size => '20 MB',
                      access-log-old-files => '5',
                      debug-mode => 'off',
                      verbose-security => '${buildout:verbose-security}',
                      deprecation-warnings => '${buildout:deprecation-warnings}',
                    },
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

  plone::buildoutsection { "zopepy_$name":
    section_name => "zopepy",
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

  plone::buildoutsection { "precompiler_$name":
    section_name => "precompiler",
    cfghash      => { recipe => 'plone.recipe.precompiler',
                      eggs => '${instance:eggs}',
                      compile-mo-files => 'true',
                      extra-paths => '${buildout:directory}/products',
                    },
    buildout_dir => "${install_dir}/$name",
  }

  # This recipe installs the plonectl script and a few other convenience items.
  # For options see http://pypi.python.org/pypi/plone.recipe.unifiedinstaller

  plone::buildoutsection { "unifiedinstaller_$name":
    section_name => "unifiedinstaller",
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
      concat::fragment { "plone_upstart_instance_$name":
        target  => "/etc/init/plone.conf",
        content => "exec sudo -u $plone_user $install_dir/$name/bin/plonectl start\n",
        order   => '99',
      }
    }
  }


}
