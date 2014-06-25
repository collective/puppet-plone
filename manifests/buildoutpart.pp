# buildoutpart.pp

define plone::buildoutpart ( $part_name     = $name,
                             $cfghash       = {},
                             $buildout_dir  = $plone::params::buildout_dir,
                             $order         = '99',
                           ) {

  concat::fragment { "part_def_$name":
    target  => "${buildout_dir}/buildout.cfg",
    content => "   $part_name\n",
    order   => "04${order}",
  }

  plone::buildoutsection { "part_$name":
    section_name => "$part_name",
    cfghash      => $cfghash,
    buildout_dir => "${buildout_dir}",
    order        => "99${order}",
  }

}
