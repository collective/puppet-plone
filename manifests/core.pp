# core.pp

class plone::core {
  # these packages are user for zope, zeo, and just about anything python
  $sys_packages = [ 'zlib1g-dev',
                    'libssl-dev',
                    'libjpeg62-dev',
                    'libjpeg62',
                    'libfreetype6',
                    'libfreetype6-dev',
                    'libcurl4-openssl-dev',
                  ]
  package { $sys_packages: ensure => "installed" }

}

