plan splunk_qd::search(Boolean $restore = false) {

  $searcher = get_targets('searcher')

  $searcher.apply_prep

  #Compile the manifest block into a catalog
  apply($searcher) {
    class { 'splunk::params':
      version => '7.2.5',
      build   => '088f49762779',
    }
    class { 'splunk::enterprise': package_ensure => latest, manage_password => true }

    $addons.each |$addon| {
      splunk::addon { $addon['name']:
        splunkbase_source => "puppet:///modules/splunk_qd/addons/${addon['filename']}",
        inputs            => $addon['inputs'],
      }
    }
  }

  if $restore {
    run_task('service::linux', $searcher, { action => 'stop', name => 'Splunkd' })
    run_command('rm -rf /opt/splunk/var/lib/splunk/defaultdb/db', $searcher, 'Nuke existing hot/warm database')
    upload_file('splunk_qd/backups/splunk_db_backup.tar.gz', '/tmp/splunk_db_backup.tar.gz', $searcher, 'Uploading Splunk Backup Archive')
    run_command('tar -xzvf /tmp/splunk_db_backup.tar.gz -C /opt/splunk/var/lib/splunk/defaultdb', $searcher, 'Expanding Splunk Backup Archive')
    run_command('rm /tmp/splunk_db_backup.tar.gz', $searcher, 'Cleaning up Splunk Backup Archive')
    run_task('service::linux', $searcher, { action => 'start', name => 'Splunkd' })
  }
}
