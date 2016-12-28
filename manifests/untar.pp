define tarball::untar (
                        $basedir     = '/opt',
                        $packagename = $name,
                        $filetype    = 'tar',
                        $srcdir      = '/usr/local/src',
                        $source_url  = undef,
                        $source      = undef,
                      ) {

  Exec {
    path => '/bin:/sbin:/usr/bin:/usr/sbin',
  }

  if($source_url==undef and $source==undef)
  {
    fail('source_url or source must be defined')
  }

  if($source_url!=undef and $source!=undef)
  {
    fail('source_url and source cannot be defined at the same time')
  }

  exec { "mkdir ${srcdir} ${packagename}":
    command => "mkdir -p ${srcdir}",
    creates => $srcdir,
  }

  exec { "which wget ${packagename}":
    command => 'which wget',
    unless  => 'which wget',
  }

  if($source_url==undef)
  {
    file { "${srcdir}/${packagename}.${filetype}":
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0655',
      source  => $source,
      require => Exec["mkdir ${srcdir} ${packagename}"],
    }
  }
  else
  {
    exec { "wget ${source_url}":
      command => "wget ${source_url} -O ${srcdir}/${packagename}.${filetype}",
      creates => "${srcdir}/${packagename}.${filetype}",
      require => Exec[ [ "mkdir ${srcdir} ${packagename}", "which wget ${packagename}" ] ],
    }

    file { "${srcdir}/${packagename}.${filetype}":
      ensure  => 'present',
      owner   => 'root',
      group   => 'root',
      mode    => '0655',
      require => Exec["wget ${source_url}"],
    }
  }

  case $filetype
  {
    'tar':
    {
      exec { "which tar ${packagename}":
        command => "which tar",
        unless  => 'which tar',
      }

      exec { "mkdir ${basedir} ${packagename}":
        command => "mkdir -p ${basedir}/${packagename}",
        creates => "${basedir}/${packagename}",
      }

      exec { "untar ${packagename}":
        command => "tar xf ${srcdir}/${packagename}.${filetype} -C ${basedir}/${packagename}",
        require =>  [
                      Exec[ [ "mkdir ${basedir} ${packagename}", "which tar ${packagename}" ] ],
                      File["${srcdir}/${packagename}.${filetype}"]
                    ],
      }
    }
    default:
    {
      fail("unsupported filetype: ${filetype}")
    }
  }

}