class splunk_qd::profile::forward(
  Optional[String[1]] $search_host          = undef,
  Optional[String[1]] $deployment_server    = undef,
  Integer             $deployment_port      = 8089,
  Boolean             $manage_addons        = true,
  String              $version              = undef,
  String              $build                = undef,
  String              $passwd_hash          = '$6$jxSX7ra2SNzeJbYE$J95eTTMJjFr/lBoGYvuJUSNKvR7befnBwZUOvr/ky86QGqDXwEwdbgPMfCxW1/PuB/IkC94QLNravkABBkVkV1',
  Array               $addons               = [],
  Optional[String[1]] $addon_source_path    = undef
) {

  # Universal Forwarders can be installed without an inventory.yaml file, where
  # plan add-on configuration is stored so in absence of that the plan can
  # point the forwarders to an existing configured Splunk deployment server
  if $deployment_server {
    $_extra_params    = {}
    $override_outputs = { 'forwarder_output' => {} }

    splunkforwarder_deploymentclient { 'deploymentServer':
      section => 'target-broker:deploymentServer',
      setting => 'targetUri',
      value   => "${deployment_server}:${deployment_port}",
    }
  } else {
    $_extra_params = { 'server' =>  $search_host }
    $override_outputs = {}
  }

  # Implement forwarder installation on Windows using Chocolately instead of
  # default MSI providers so we can manage upgrades
  if $facts['osfamily'] == 'Windows' {
    $_extra_forwarder = merge($override_outputs, {
      'package_provider' => 'chocolatey',
      'package_name'     => 'splunk-universalforwarder',
      'install_options'  => [],
    })
    class { 'chocolatey': before => Class['splunk::forwarder'] }
    class { 'archive':    before => Class['splunk::forwarder'] }

    # Work around for https://github.com/voxpupuli/puppet-archive/issues/362
    file { 'C:/ProgramData/staging':
      ensure => directory,
      before => Class['archive']
    }
    file { 'C:/ProgramData/staging/splunk':
      ensure => directory,
      before => Class['archive'],
    }
  } else {
    $_extra_forwarder = $override_outputs
  }

  # Declaring Class[splunk::params] here is how you control which version of
  # Splunk Universal Forwarder is downloaded and installed and set the host
  # you wish to forward your data to for indexing.
  class { 'splunk::params':
    version => $version,
    build   => $build,
    *       => $_extra_params,
  }

  # The class that actually sets up Splunk Universal forwarder is set here to
  # manage the password file so we know the admin password so we can long in and
  # don't be concerned over it is implying we're going to always install the
  # latest release, the version downloaded is dictaed by Class[splunk::params]
  # so packages will only upgrade if you specify a newer version parameter
  # there.
  class { 'splunk::forwarder':
    package_ensure => $facts['osfamily'] ? {
      'Windows' => present,
      default   => latest,
    },
    seed_password  => true,
    password_hash  => $passwd_hash,
    *              => $_extra_forwarder,
  }

  # Redirect where add-ons are obtained if someone wants to built out a
  # testdrive with those not included in the module
  if $addon_source_path {
    $_addon_source_path = $addon_source_path
  } else {
    $_addon_source_path = 'puppet:///modules/splunk_qd/addons'
  }

  # Its safe to iterate over an empty array, effectively a noop if you haven't
  # passed in a list of addons to be managed but if you have and just simply
  # don't wish to manage them temporarily then set $manage_addons to false.
  if $manage_addons {
    $addons.each |$addon| {
      if $facts['osfamily'] == 'Windows' {
        # More work arounds for voxpupuli/puppet-archive#362
        file { $addon['name']:
          path   => "C:/ProgramData/staging/splunk/${addon['filename']}",
          source => "${_addon_source_path}/${addon['filename']}",
          before => Splunk::Addon[$addon['name']],
        }
        splunk::addon { $addon['name']:
          splunkbase_source => "C:/ProgramData/staging/splunk/${addon['filename']}",
          inputs            => $addon['inputs'],
          owner             => 'Administrator',
          notify            =>  Class['splunk::forwarder::service'],
        }
      } else {
        splunk::addon { $addon['name']:
          splunkbase_source => "${_addon_source_path}/${addon['filename']}",
          inputs            => $addon['inputs'],
          notify            =>  Class['splunk::forwarder::service'],
        }
      }

      # If the add-on has a set of settings that are set outside of inputs.conf
      # then they should be added to the `additional_settings` hash,
      # puppet/splunk doesn't currently understand all files that configuration
      # can be storred in so this is implemented with raw usage of ini_setting.
      if $addon['additional_settings'] {
        $addon['additional_settings'].each |$setting, $values| {
          ini_setting { "${addon['name']}_${values['filename']}_${values['section']}_${setting}":
            ensure         => present,
            path           =>  "${splunk::params::forwarder_homedir}/etc/apps/${addon['name']}/local/${values['filename']}",
            section        => $values['section'],
            setting        => $setting,
            value          => $values['value'],
          }
        }
      }
    }
  }
}
