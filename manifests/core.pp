# core.pp

class plone::core {
  # these packages are user for zope, zeo, and just about anything python
  $sys_packages = [ 'python-setuptools',
                   'python2.7-dev',
                   'python-pkg-resources',
                   'zlib1g-dev',
                   'libssl-dev',
                   'libjpeg62-dev',
                   'libjpeg62',
                   'libfreetype6',
                   'libfreetype6-dev',
                   'libc6-dev',
                   'gcc-4.4', 'make', 'build-essential',
                   'libcurl4-openssl-dev',
                   'software-properties-common',
                  ]
  package { $sys_packages: ensure => "installed" }

}

