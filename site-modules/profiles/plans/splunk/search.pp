plan profiles::splunk::search() {

  $searcher = get_targets('searcher')

  $searcher.apply_prep

  #Compile the manifest block into a catalog
  apply($searcher) {
    class { 'splunk::params':
      version => '7.2.5',
      build   => '088f49762779',
    }
    class { 'splunk::enterprise': package_ensure => latest, manage_password => true }
  }
}
