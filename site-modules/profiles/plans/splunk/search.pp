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

  # These files need to eventually be removed from the module and capable of
  # installing a dynamic list of addons, should look into adding to
  # puppet-splunk
  $installed = run_command('/opt/splunk/bin/splunk display app -auth admin:changeme', $searcher, '_catch_errors' => true).first['stdout'].split('\n').match(/^\S+/).flatten
  unless 'TA-puppet-report-viewer' in $installed {
    upload_file('profiles/splunk/addons/puppet-report-viewer_135.tgz', '/tmp/puppet-report-viewer_135.tgz', $searcher, 'Uploading Splunk Addon: Puppet Report Viewer')
    $rv_installed = run_command('/opt/splunk/bin/splunk install app -auth admin:changeme /tmp/puppet-report-viewer_135.tgz', $searcher, '_catch_errors' => true)
    run_command('rm /tmp/puppet-report-viewer_135.tgz', $searcher)
  }
  unless 'TA-puppet-tasks-actionable' in $installed {
    upload_file('profiles/splunk/addons/puppet-tasks-actionable-alerts-for-splunk_101.tgz', '/tmp/puppet-tasks-actionable-alerts-for-splunk_101.tgz', $searcher, 'Uploading Splunk Addon: Puppet Tasks Actionable Alerts')
    $aa_installed = run_command('/opt/splunk/bin/splunk install app -auth admin:changeme /tmp/puppet-tasks-actionable-alerts-for-splunk_101.tgz', $searcher, '_catch_errors' => true)
    run_command('rm /tmp/puppet-tasks-actionable-alerts-for-splunk_101.tgz', $searcher)
  }

  # While addons are managed outside of Puppet we have to do this twice to
  # restart services and good evidence for integrating addons into module
  if true in [defined('$rv_installed'), defined('$aa_installed')] {
    apply($searcher) {
      class { 'splunk::params':
        version => '7.2.5',
        build   => '088f49762779',
      }
      class { 'splunk::enterprise': package_ensure => latest, manage_password => true }
      notify { 'trigger':} ~> Class['splunk::enterprise::service']
    }
  }
}
