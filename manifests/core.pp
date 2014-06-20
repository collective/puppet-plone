class plone::core {
      # these packages are user for zope, zeo, and just about anything python
      $sys_packages = $operatingsystem ? {
            Archlinux => [
                  'python2',
                  'python2-pillow',
                  'python2-virtualenv',
                  'zlib',
                  'base-devel',
                  'openssl',
                  'libjpeg-turbo',
                  'curl',
            ],
            default => [
                  'python-setuptools',
                  'python2.7-dev',
                  'python-virtualenv',
                  'python-pkg-resources',
                  'zlib1g-dev',
                  'libssl-dev',
                  'libjpeg62-dev',
                  'libjpeg62',
                  'libfreetype6',
                  'libfreetype6-dev',
                  'libc6-dev',
                  'libc-dev',
                  'gcc-4.4', 'make', 'build-essential',
                  'libcurl4-openssl-dev',
                  'software-properties-common',
            ],
      }
      package { $sys_packages: ensure => "installed" }
}

# vim: set ts=6 shiftwidth=6 expandtab:
