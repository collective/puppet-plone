# site.pp

define plone::site ( $id               = $plone::params::default_site_id,
                     $site_replace     = $plone::params::default_site_replace,
                     $container_path   = $plone::params::default_site_container,
                     $protocol         = $plone::params::default_site_protocol,
                     $port             = $plone::params::default_site_port,
                     $use_vhm          = $plone::params::default_site_use_vhm,
                     $default_language = $plone::params::default_site_language,
                     $has_filestorage  = $ploen::params::default_site_has_filestorage,
                     $profiles         = [],
                     $profiles_initial = [],
                     $products         = [],
                     $products_initial = [],
                     $instance_name,
                     $install_dir      = $plone::params::plone_install_dir,
                    ) {

  plone::buildoutpart { "site_$name":
    part_name    => "site_$name",
    cfghash      => { recipe           => 'collective.recipe.plonesite',
                      site-id          => $id,
                      site-replace     => $site_replace,
                      container-path   => $container_path,
                      instance         => 'instance',
                      protocol         => $protocol,
                      port             => $port,
                      use-vhm          => $use_vhm,
                      default-language => $default_language,
                      profiles         => $profiles,
                      profiles-initial => $profiles_initial,
                      products         => $products,
                      products_initial => $products_initial,
                      before-install   => 'bin/buildout install filestorage'
                    },
    buildout_dir => "${install_dir}/${$instance_name}",
  }


}
