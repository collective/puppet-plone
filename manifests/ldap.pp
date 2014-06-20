class plone::ldap {
      $ldapsys = $operatingsystem ? {
            Archlinux => [
                  'libldap',
                  'libsasl',
            ],
            default => [
                  'ldap-utils',
                  'python-ldap',
                  'ldap-auth-client',
                  'libldap2-dev',
                  'libsasl2-dev',
            ],
      }

      package { $ldapsys: ensure => "installed" }
}

# vim: set ts=6 shiftwidth=6 expandtab:
