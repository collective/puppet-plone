# filestorage.pp

define plone::filestorage ( $fs_name         = $name, 
                            $instance_name,
                            $install_dir     = $plone::params::plone_install_dir,
                            $blobstorage_dir = $plone::params::filestorage_blobdir, 
                    ) {

  if !defined(Plone::Buildoutpart["filestorage_${instance_name}"]) { 
    plone::buildoutpart { "filestorage_${instance_name}":
      part_name    => "filestorage",
      cfghash      => { recipe => 'collective.recipe.filestorage',
                        location => 'var/filestorage/Data_%(fs_part_name)s.fs',
                        blob-storage => $blobstorage_dir,
                        zodb-mountpoint => '/%(fs_part_name)s',
                        #backup => 'backup',
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

}
