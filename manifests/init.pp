# == Class: facter
#
# Manage facter
#
class facter (
  $manage_package         = undef,
  $package_name           = 'facter',
  $package_ensure         = 'present',
  $manage_facts_d_dir     = true,
  $purge_facts_d          = false,
  $facts_d_dir            = '/etc/facter/facts.d',
  $facts_d_owner          = 'root',
  $facts_d_group          = 'root',
  $facts_d_mode           = '0755',
  $path_to_facter         = '/usr/bin/facter',
  $path_to_facter_symlink = '/usr/local/bin/facter',
  $ensure_facter_symlink  = false,
  $facts_hash             = {},
  $facts_hash_hiera_merge = false,
  $facts_file             = 'facts.txt',
  $facts_file_owner       = 'root',
  $facts_file_group       = 'root',
  $facts_file_mode        = '0644',
) {

  validate_string($package_ensure)

  validate_absolute_path($facts_d_dir)

  validate_re($facts_d_mode,
    '^\d{4}$',
    "facter::facts_d_mode must be a four digit mode. Detected value is <${facts_d_mode}>."
  )

  # validate params
  validate_absolute_path($path_to_facter_symlink)
  validate_absolute_path($path_to_facter)

  if versioncmp($::puppetversion, '4.0.0') >= 0 {
    $manage_package_real = false
  } elsif $manage_package == undef {
    $manage_package_real = true
  } else {
    $manage_package_real = $manage_package
  }

  if is_string($manage_package_real) {
    $manage_package_bool = str2bool($manage_package_real)
  } else {
    $manage_package_bool = $manage_package_real
    validate_bool($manage_package_bool)
  }

  if is_string($manage_facts_d_dir) {
    $manage_facts_d_dir_real = str2bool($manage_facts_d_dir)
  } else {
    validate_bool($manage_facts_d_dir)
    $manage_facts_d_dir_real = $manage_facts_d_dir
  }

  if is_string($purge_facts_d) {
    $purge_facts_d_real = str2bool($purge_facts_d)
  } else {
    $purge_facts_d_real = $purge_facts_d
  }
  validate_bool($purge_facts_d_real)

  if !is_string($package_name) and !is_array($package_name) {
    fail('facter::package_name must be a string or an array.')
  }

  if $manage_package_bool == true {

    package { $package_name:
      ensure => $package_ensure,
    }
  }

  if $manage_facts_d_dir_real == true {

    exec { "mkdir_p-${facts_d_dir}":
      command => "mkdir -p ${facts_d_dir}",
      unless  => "test -d ${facts_d_dir}",
      path    => '/bin:/usr/bin',
    }

    file { 'facts_d_directory':
      ensure  => 'directory',
      path    => $facts_d_dir,
      owner   => $facts_d_owner,
      group   => $facts_d_group,
      mode    => $facts_d_mode,
      purge   => $purge_facts_d_real,
      recurse => $purge_facts_d_real,
      require => Exec["mkdir_p-${facts_d_dir}"],
    }
  }

  if is_string($ensure_facter_symlink) {
    $ensure_facter_symlink_bool = str2bool($ensure_facter_symlink)
  } else {
    $ensure_facter_symlink_bool = $ensure_facter_symlink
  }
  validate_bool($ensure_facter_symlink_bool)

  # optionally create symlinks to facter binary
  if $ensure_facter_symlink_bool == true {

    file { 'facter_symlink':
      ensure => 'link',
      path   => $path_to_facter_symlink,
      target => $path_to_facter,
    }
  }

  validate_absolute_path("${facts_d_dir}/${facts_file}")
  file { 'facts_file':
    ensure => file,
    path   => "${facts_d_dir}/${facts_file}",
    owner  => $facts_file_owner,
    group  => $facts_file_group,
    mode   => $facts_file_mode,
  }

  # optionally push fact to client
  if is_string($facts_hash_hiera_merge) {
    $facts_hash_hiera_merge_real = str2bool($facts_hash_hiera_merge)
  } else {
    $facts_hash_hiera_merge_real = $facts_hash_hiera_merge
  }
  validate_bool($facts_hash_hiera_merge_real)

  if $facts_hash_hiera_merge_real == true {
    $facts_hash_real = hiera_hash('facter::facts_hash', {})
  } else {
    $facts_hash_real = $facts_hash
  }

  validate_hash($facts_hash_real)
  if ! empty( $facts_hash_real ) {
    $facts_defaults = {
      'file'      => $facts_file,
      'facts_dir' => $facts_d_dir,
    }
    create_resources('facter::fact',$facts_hash_real, $facts_defaults)
  }
}
