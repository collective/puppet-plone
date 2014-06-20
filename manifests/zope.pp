class plone::zope {
      include plone::core

      $zopesys = $operatingsystem ? {
            Archlinux => [
                  'libxml2',
                  'libxslt',
            ],
            default => [
                  'libxml2-dev',
                  'libxslt-dev',
                  'libpq-dev',
                  'python-lxml',
            ]
      }

      package { $zopesys: ensure => "installed" }

}

# vim: set ts=6 shiftwidth=6 expandtab:
