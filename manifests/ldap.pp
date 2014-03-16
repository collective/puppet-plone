class plone::ldap{
      $ldapsys = [
           'ldap-utils',
	   'python-ldap',
	   'ldap-auth-client',
	   'libldap2-dev',
	   'libsasl2-dev',
      ]

      package { $ldapsys: ensure => "installed" }

}
