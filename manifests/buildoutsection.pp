# buildoutsection.pp

define plone::buildoutsection ( $section_name  = $name, 
                                $cfghash       = {},
				$buildout_dir  = $plone::params::buildout_dir,
                               ) {

  concat::fragment { "buildoutcfg_section_$name":
    target  => "${buildout_dir}/buildout.cfg",
    content => template('plone/buildout.cfg.erb'),
    order   => '99',
  }

}
