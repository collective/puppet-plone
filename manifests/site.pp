# site.pp

define plone::site ( $site_name        = $name,
                     $id               = $plone::params::default_site_id,
                     $site_replace     = $plone::params::default_site_replace,
                     $container_path   = $plone::params::default_site_container,
                     $protocol         = $plone::params::default_site_protocol,
                     $port             = $plone::params::default_site_port,
                     $use_vhm          = $plone::params::default_site_use_vhm,
                     $default_language = $plone::params::default_site_language,
                     $add_mountpoint   = $plone::params::default_site_add_mountpoint,
                     $admin_user       = $plone::params::default_site_admin_user,
                     $enabled          = $plone::params::default_site_enabled,
                     $refresh_only     = $plone::params::default_site_refresh_only,
                     $plone_user       = $plone::params::plone_user,
                     $plone_group      = $plone::params::plone_group,
                     $install_dir      = $plone::params::plone_install_dir,
                     $unless           = undef,
                     $pre_extras       = '',
                     $post_extras      = '',
                     $before_install   = '',
                     $profiles         = [],
                     $profiles_initial = [],
                     $products         = [],
                     $products_initial = [],
                     $instance_name,
                    ) {

  file { "${install_dir}/${$instance_name}/.site_${site_name}-installed.cfg":
    replace => "no",
    ensure  => "present",
    content => "[buildout]\nparts = ",
    owner   => $plone_user,
    group   => $plone_group,
    mode    => 660,
  }

  buildout::cfgfile { "site_${name}":
    filename => "site_${site_name}.cfg",
    dir      => "${install_dir}/${$instance_name}",
    user     => $plone_user,
    group    => $plone_group,
    partsext => true,
    params   => { installed      => ".site_${site_name}-installed.cfg",
                  extends        => "buildout.cfg",
                  eggs-directory => "${install_dir}/buildout-cache/eggs",
                  download-cache => "${install_dir}/buildout-cache/downloads" },
    require  => File["${install_dir}/${$instance_name}/.site_${site_name}-installed.cfg"],
  }
  
  buildout::part { "site_${name}":
    part_name    => "site_${site_name}",
    cfghash      => { recipe           => 'collective.recipe.plonesite',
                      site-id          => $id,
                      site-replace     => $site_replace,
                      container-path   => $container_path,
                      enabled          => $enabled,
                      instance         => 'instance',
                      protocol         => $protocol,
                      port             => $port,
                      use-vhm          => $use_vhm,
                      admin-user       => $admin_user,
                      default-language => $default_language,
                      profiles         => $profiles,
                      profiles-initial => $profiles_initial,
                      products         => $products,
                      products-initial => $products_initial,
                      before-install   => $before_install,
                      pre-extras       => $pre_extras,
                      post-extras      => $post_extras,
                      add-mountpoint   => $add_mountpoint,                 
                    },
    buildout_dir => "${install_dir}/${$instance_name}",
    cfgfile      => "site_${site_name}.cfg",
  }

  exec { "install_site_$name":
    cwd         => "${install_dir}/${$instance_name}",
    command     => "${install_dir}/${$instance_name}/bin/buildout -c ${install_dir}/${$instance_name}/site_${site_name}.cfg install site_${site_name}",
    subscribe   => [ Buildout::Cfgfile["site_${name}"] ],
    refreshonly => $refresh_only,
    unless      => $unless,
    user        => $plone_user,
    logoutput   => true,
    timeout     => 600,
  }

}
