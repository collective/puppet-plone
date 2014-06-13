# buildout.pp
# requires https://github.com/stankevich/puppet-python
#          https://github.com/example42/puppet-wget
#          https://github.com/puppetlabs/puppetlabs-concat

define plone::buildout ( $buildout_dir       = $plone::params::buildout_dir,
                         $buildout_cache_dir = $plone::params::buildout_cache_dir,
                         $source             = $plone::params::buildout_source, 
                         $user               = $plone::params::buildout_user,
                         $group              = $plone::params::buildout_group,
                         $buildout_params    = {},
                       ) {

  include plone::params
   
  if !defined(Class['python']) {
    class { 'python':
      version    => 'system',
      dev        => true,
      virtualenv => true,
      pip        => true,
    }
  } 
  
  # Clone buildout
  include wget
  file { "${buildout_dir}/$name": 
    ensure  => directory,
    owner   => $user,
    group   => $group,
    recurse => true,
  }

  if !defined(File["${buildout_dir}/${buildout_cache_dir}"]) {
    file { [ "${buildout_dir}/${buildout_cache_dir}",
             "${buildout_dir}/${buildout_cache_dir}/eggs",
             "${buildout_dir}/${buildout_cache_dir}/downloads"] :
      ensure  => directory,
      owner   => $user,
      group   => $group,
    }
  }

  wget::fetch { "bootstrap_$name":
    source      => $source,
    destination => "${buildout_dir}/$name/bootstrap.py",
    user        => $user,
    require     => File["${buildout_dir}/$name"],
  }
 
  # Create virtualenv
  python::virtualenv { "${buildout_dir}/$name":
    ensure       => present,
    version      => 'system',
    owner        => $user,
    group        => $group,
    cwd          => "${buildout_dir}/$name",
    require      => [ File["${buildout_dir}/$name"],
                    ],
  }

  exec { "run_bootstrap_$name":
    creates => "${buildout_dir}/$name/bin/buildout",
    cwd => "${buildout_dir}/$name",
    command => "${buildout_dir}/$name/bin/python ${buildout_dir}/$name/bootstrap.py",
    subscribe => Wget::Fetch["bootstrap_$name"],
    require => [ Python::Virtualenv["${buildout_dir}/$name"],
                 Concat["${buildout_dir}/$name/buildout.cfg"],
               ],
    user => $user,
  }  

  concat { "${buildout_dir}/$name/buildout.cfg":
    owner => $user, group => $group, mode => 440,
  }

  concat::fragment { "buildoutcfg_header_$name":
    target  => "${buildout_dir}/$name/buildout.cfg",
    content => "# This file is managed by Puppet. Changes will be periodically overwritten.\n\n",
    order   => '01',
  }

  $buildout_default_params = { eggs-directory => "${buildout_dir}/${buildout_cache_dir}/eggs",
                               download-cache => "${buildout_dir}/${buildout_cache_dir}/downloads",
                               parts          => "" }   

  $buildout_final_params = merge($buildout_default_params, $buildout_params)
 
  plone::buildoutsection { "buildout_$name":
    section_name => "buildout",
    cfghash      => $buildout_final_params,
    buildout_dir => "${buildout_dir}/$name",
  }

  exec { "run_buildout_$name":
    cwd => "${buildout_dir}/$name",
    command => "${buildout_dir}/$name/bin/buildout -c ${buildout_dir}/$name/buildout.cfg",
    subscribe => [ Exec["run_bootstrap_$name"],
                   File["${buildout_dir}/$name/buildout.cfg"],
                 ],
    refreshonly => true,
    user => $user,
    logoutput => true,
    timeout => 0,
  }
  
}
