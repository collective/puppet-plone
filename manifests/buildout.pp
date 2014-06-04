class plone::buildout($base_dir, $buildout_dir, $repo_url, $user, $group, $server_config) {

    package { 'git': ensure => "installed" }

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

    exec { "create_virtualenv":
        command => $operatingsystem ? {
            Archlinux => "/usr/bin/virtualenv2 --no-setuptools ${buildout_dir}",
            default => "/usr/bin/virtualenv --no-setuptools ${buildout_dir}",
        },
        creates => "${buildout_dir}/bin/python",
        user =>	$user,
        require => Exec['clone_buildout'],
    }

    file { "${base_dir}":
        ensure => "directory",
        owner => $user,
        group => $group,
    }

    exec{ "clone_buildout":
        creates => "${buildout_dir}",
        command => "/usr/bin/git clone ${repo_url} ${buildout_dir}",
        cwd => "${base_dir}",
        require => [ Package['git'],
                     User[$user],
                     File[$base_dir], ],
        user =>	$user,
    }

    exec { 'run_bootstrap':
        creates => "${buildout_dir}/bin/buildout",
        cwd => "${buildout_dir}",
        command => "${buildout_dir}/bin/python ${buildout_dir}/bootstrap.py -c ${server_config}",
        subscribe => Exec['clone_buildout'],
        require => Exec['create_virtualenv'],
        user => $user,
    }

    exec { 'initial_buildout':
        cwd => "${buildout_dir}",
        command => "${buildout_dir}/bin/buildout -c ${buildout_dir}/${server_config}",
        # buildout may depend on finding the correct user and group in the environment in some cases.
        environment => [ "USER=$user",
                         "GROUP=$group",
                       ],
        subscribe => Exec['run_bootstrap'],
        # this operation may very well take a fair amount of time.
        timeout => 3600,
        user => $user,
    }

    exec { 'start_supervisor':
        creates => "${buildout_dir}/var/supervisor.sock",
        cwd => "${buildout_dir}",
        command => "${buildout_dir}/bin/supervisord",
        subscribe => Exec['initial_buildout'],
        user => $user,
    }
}

# vim: ts=4 shiftwidth=4 expandtab:
