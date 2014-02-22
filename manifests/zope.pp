class plone::zope{            
      include plone::core
      
      $zopesys = [ 
           'libxml2-dev', 
           'libxslt-dev', 
	   'libpq-dev', 
   	   'python-lxml',
      ]

      package { $zopesys: ensure => "installed" }

}