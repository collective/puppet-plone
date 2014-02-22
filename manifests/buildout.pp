class plone::buildout($buildout_dir){

    file { "$buildout_dir":
        ensure => directory,
    }

    file { "${buildout_dir}/var":
        ensure => directory,
	require => File[$buildout_dir],
    }

    file { "${buildout_dir}/zope-eggs":
        ensure => "directory",
        require	=> File[$buildout_dir],
    }
}