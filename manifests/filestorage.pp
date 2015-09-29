# filestorage.pp

define plone::filestorage ( $fs_name         = $name, 
                            $instance_name,
                            $install_dir     = $plone::params::plone_install_dir,
                            $blobstorage_dir = $plone::params::filestorage_blobdir,
                            $enable_backup   = $plone::params::filestorage_enable_backup,
                            $replicate_from  = undef,
                            $replicate_to    = undef,
                    ) {

  if !defined(Buildout::Part["filestorage_${instance_name}"]) {
    $fs_cfghash = { recipe => 'collective.recipe.filestorage',
                    location => 'var/filestorage/Data_%(fs_part_name)s.fs',
                    blob-storage => $blobstorage_dir,
                    zodb-mountpoint => '/%(fs_part_name)s',
                  }
 
    buildout::part { "filestorage_${instance_name}":
      part_name    => "filestorage",
      cfghash      => $enable_backup ? {
                        true  => merge ( $fs_cfghash, { backup => 'backup' } ),
                        false => $fs_cfghash,
                      },
      buildout_dir => "${install_dir}/${$instance_name}",
      order        => '00',
    }
    concat::fragment { "fstorage_parts_${instance_name}":
      target  => "${install_dir}/${$instance_name}/buildout.cfg",
      content => "parts = \n",
      order   => "9901",
    }
  }

  concat::fragment { "fstorage_def_$name":
    target  => "${install_dir}/${$instance_name}/buildout.cfg",
    content => "   ${fs_name}\n",
    order   => "9902",
  }

  if $replicate_from {
    notify { "replicate_from": }
    #buildout::part { "filestorage_${name}":
    #  part_name    => "filestorage",
    #  cfghash      => { replicate-from => "${zeoserver:replicate-from}0" },
    #  buildout_dir => "${install_dir}/${$instance_name}",
    #  order        => '02',
    #}
  }


}
