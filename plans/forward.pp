plan splunk_qd::forward() {

  $searcher = get_targets('searcher')
  $forwarders = get_targets('forwarders')

  $search_host = $searcher[0].host

  $forwarders.apply_prep

  apply($forwarders) {
    class { 'splunk::params':
      server  => $search_host,
      version => '7.2.5',
      build   => '088f49762779',
    }

    class { 'splunk::forwarder': package_ensure => latest, manage_password => true }

    splunkforwarder_input { 'var_log_messages':
      section => 'monitor:///var/log/messages',
      setting => 'disabled',
      value   => '0',
      notify  => Service['SplunkForwarder'],
    }
  }
}
