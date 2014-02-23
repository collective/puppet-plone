class plone::buildout($buildout_dir, $repo_url, $user, $server_config){

    file { "${buildout_dir}/var":
        ensure => directory,
	require => Exec['clone_buildout'],
        owner => $user,
    }

    file { "${buildout_dir}/zope-eggs":
        ensure => "directory",
        require	=> Exec['clone_buildout'],
        owner => $user,
    }

    file { "${buildout_dir}/buildout-cache":
        ensure => "directory",
        require => Exec['clone_buildout'],
        owner => $user,
    }

    file { "${buildout_dir}/buildout-cache/downloads":
        ensure => "directory",
	require => File["$buildout_dir/buildout-cache"],
        owner => $user,
    }

    # srv needs permissions of hte user to clone appropriately
    file { "/srv":
        mode  => '0664',
        owner => $user,
        group => 'www',
    }

    exec { "create_virtualenv":
        command => "/usr/bin/virtualenv --no-setuptools ${buildout_dir}",
        creates => "${buildout_dir}/bin/python",
        user =>	$user,
        require => Exec['clone_buildout'],
    }

    exec{ "clone_buildout":
        creates => "${buildout_dir}",
        command => "/usr/bin/git clone ${repo_url} ${buildout_dir}",
        cwd => '/srv',
        require => [ Package['git'], 
                     User[$user],
                     File['/srv'], ],
        user =>	$user,
   }

   exec { 'run_bootstrap':
      creates => "${buildout_dir}/buildout",
      cwd => "${buildout_dir}",
      command => "${buildout_dir}/bin/python ${buildout_dir}/bootstrap.py",
      subscribe => Exec['clone_buildout'],
      require => Exec['create_virtualenv'],      
      user => $user,
    }

   exec { 'initial_buildout':
      cwd => "${buildout_dir}",
      command => "${buildout_dir}/bin/buildout -c ${buildout_dir}/${server_config}",
      subscribe => Exec['run_bootstrap'],
      user => $user,
   }

   exec { 'start_supervisor':
      cwd => "${buildout_dir}",
      command => "${buildout_dir}/bin/supervisord",
      subscribe => Exec['initial_buildout'],
   }
}