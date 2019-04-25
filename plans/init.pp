plan splunk_qd(
  String  $version                 = '7.2.5',
  String  $build                   = '088f49762779',
  Optional[String[1]] $search_host = undef,
  Boolean $manage_addons           = true,
  Boolean $manage_forwarders       = true,
  Boolean $manage_search           = true,
) {


  $search_head = get_targets('search_head')

  if $manage_search {
    $search_head.apply_prep

    apply($search_head) {
      class { 'splunk_qd::profile::search':
        version       => $version,
        build         => $build,
        manage_addons => $manage_addons,
        addons        => $addons,
      }
    }
  }

  if $manage_forwarders {
    $forwarders = get_targets('forwarders')
    if $search_host {
      $_search_host = $search_host
    } else {
      $_search_host = $search_head[0].host
    }

    $forwarders.apply_prep

    apply($forwarders) {
      class { 'splunk_qd::profile::forward':
        version       => $version,
        build         => $build,
        manage_addons => $manage_addons,
        addons        => $addons,
        search_host   => $_search_host,
      }
    }
  }
}
