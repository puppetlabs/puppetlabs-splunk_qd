# @summary
#   This Bolt Plan is the primary jumping off point for leveraging the  Splunk
#   Quick Deploy module and facilitates orchestrating purpose built profiles
#   to utilize the **puppet/splunk** module through remote execution of
#   agentless Puppet. Having been built upon existing Puppet code, the indended
#   operating mode of this plan is a declarative one. It builds a simple
#   interface upon powerful lower level modules. Since **puppetlabs/splunk_qd**
#   does implement profiles for abstracting certain aspects of the installation
#   and configuration of Splunk Enterprise, these profiles can easily be
#   adapted and integrated into a Puppet Enterprise infrastructure-as-code
#   environment to ensure continuous state enforcement for complex
#   organizational needs.
#
# @see https://puppetlabs.github.io/puppetlabs-splunk_qd
#
# @example Deploying the Universal Forwarder and point it at an existing Splunk Enterprise infrastructure deployment server
#   bolt plan run splunk_qd deployment_server=splunk0.example.com -t web0.example.com,web1.example.com,db2.example.com
#
# @example Install a specific version of Splunk Enterprise or upgrade to a new one
#   bolt plan run splunk_qd version=7.2.6 build=c0bf0f679ce9 -t splunk0.example.com
#
# @example Deploy a fresh instance of Splunk Entperise and Universal Forwarder with UI SSL from letsencrypt by using a populated bolt inventory file (see: [inventory.yaml](https://github.com/puppetlabs/puppetlabs-splunk_qd/blob/master/examples/inventory.yaml))
#   bolt plan run splunk_qd mode=testdrive ui_ssl=true
#
# @param version
#   The version number of either Splunk Enterprise or Universal Forwarder
#   that you wish to have downloaded from Splunk and installed
#
# @param build
#   Each version of the packages published by Splunk also have a specific build
#   string that is required for constructing the proper URL for remote fetching
#
# @param search_host
#   Parameter is optional and depends on mode of operation. If you've defined
#   an inventory group or host with the alias **search_head** than this value
#   will be transformed into that node's host name or IP address but if you
#   do not define that than this needs to be set to tell managed Universal
#   forwarders where to send their data
#
# @param deployment_server
#   Parameter is optional and and only applicable when running splunk_qd in its
#   default mode, forwarder because mode testdrive assumes full configuration
#   through Puppet
#
# @param manage_addons
#   Temporarily disable the management of add-ons when they are defined in your
#   `inventory.yaml` file, add-ons will never be managed if they are not defined
#   within the `inventory.yaml` file
#
# @param ui_ssl
#   To configure Splunk Enterprise Web with SSL and redirect traffic on port 80
#   to 443
#
# @param ui_ssl_mode
#   Switch between the two available SSL providers supported by the module
#
# @param ui_ssl_reg_email
#   When using the `letsencrypt` SSL provider you must provide an email address
#   to be used as an account that the certificate will be registered to
#
# @param ui_ssl_reg_fqdn
#   Sets the common name on the generated and signed certificate when using the
#   `letsencrypt` SSL provider
#
# @param ui_ssl_test
#   Controls which letsencrypt endpoint that SSL certificates are provisioned
#   from, if set to true then they'll be obtained from staging
#
# @param addon_source_path
#   Used for defining a source path that is different than the default in module
#   path so that add-ons can be placed somewhere that doesn't require you to
#   modify the module when defining add-ons that are obtained outside the
#   module, e.g. splunkbase
#
# @param passwd_hash
#   A password hash to see for the initial admin user, default: `changeme`
#
plan splunk_qd(
  Optional[TargetSpec]                      $nodes             = undef,
  String[1]                                 $version           = '7.2.5',
  String[1]                                 $build             = '088f49762779',
  Optional[String[1]]                       $search_host       = undef,
  Optional[String[1]]                       $deployment_server = undef,
  Enum['testdrive', 'search', 'forwarder']  $mode              = 'forwarder',
  Boolean                                   $manage_addons     = true,
  Boolean                                   $ui_ssl            = false,
  Optional[Enum['internal', 'letsencrypt']] $ui_ssl_mode       = undef,
  Optional[String[1]]                       $ui_ssl_reg_email  = undef,
  Optional[String[1]]                       $ui_ssl_reg_fqdn   = undef,
  Boolean                                   $ui_ssl_test       = false,
  Optional[String[1]]                       $addon_source_path = undef,
  String[1]                                 $passwd_hash       = '$6$E4XR.g0Sq.2JvbgT$me1K9oruJuXG09NSDv2I0wCKl9DS4ETv/XY5YqyZM5ctf.cp06JSN6x.MG2Y0lJ9zLfY6zpMn6GJNo.9O4cWH/',
) {

  # Protecting user from mode and parameter combinations that do no make sense
  if $mode == 'testdrive' and $nodes != undef {
    fail_plan('Executing splunk_qd in testdrive mode is not compatible with passing groups or a comma seperated list of targets on the CLI, mode full is dependent on the Bolt inventory file')
  }

  if $mode == 'search' and get_targets($nodes).length > 1 {
    warn('splunk_qd only supports managing a single instance of Splunk Enterprise per invocation')
  }

  if $mode == 'forwarder' and ($search_host == undef and $deployment_server == undef) {
    fail_plan('When running in mode forwarder you must supply a search_host or deployment_server parameter to inform the Universal Forwarder where to send its data or from where to obtain additional configurations')
  }

  # Conditional to ensure we manage the installation of Splunk Enterprise only
  # when the CLI mode setting is set to testdrive or search
  if $mode in ['testdrive', 'search'] {

    # This automation only supports managing a single Splunk Enterprise instance at a time
    $search = $mode ? {
      'testdrive' => get_targets('search')[0],
      default     => get_targets($nodes)[0]
    }

    # The inventory defined SSL options should be selectively overridden from
    # the CLI, to accomplish this we look them up first from inventory then
    # merge over the top the ones obtained from the CLI
    if $ui_ssl {
      $_ssl = merge($search.vars['ui_ssl'], {
        'ui_ssl_mode'      => $ui_ssl_mode,
        'ui_ssl_reg_email' => $ui_ssl_reg_email,
        'ui_ssl_reg_fqdn'  => $ui_ssl_reg_fqdn,
        'ui_ssl_test'      => $ui_ssl_test,
      }.filter |$setting| { $setting[1] != undef })
    } else {
      $_ssl = {}
    }

    # Ensure the agentless Puppet helper is installed and gather facts, you
    # always have to run the apply_prep function ahead of an apply block even if
    # the helper is installed or most Puppet modules are going to fail since
    # they heavily rely on facts
    $search.apply_prep

    # Function that starts executution of an agentless Puppet run using Bolt
    # on a remote set of nodes and stores success or failure details into a
    # variable we can us later
    $search_results = apply($search) {

      # Bolt makes it super easy to follow existing best practices and leverage
      # great pieces of content found out in out broad Puppet ecosystem, as
      # we have done here building a simple profile for managing Splunk
      # Enterprise which in turn utilizes the puppet/splunk module from Voxpupuli
      class { 'splunk_qd::profile::search':
        version           => $version,
        build             => $build,
        passwd_hash       => $passwd_hash,
        manage_addons     => $manage_addons,
        addon_source_path => defined('$addon_source_path') ? { true => $addon_source_path, default => undef },
        addons            => defined('$addons') ? { true => $addons, default => [] },
        ui_ssl            => $ui_ssl,
        ssl               => $_ssl,
      }
    }
    if $search_results.first.report['status'] == 'changed' {
      if ! $_ssl.empty {
        if $_ssl['ui_ssl_reg_fqdn'] {
          $success_url = "https://${_ssl['ui_ssl_reg_fqdn']}"
        } else {
          $success_url = "https://${search.host}"
        }
      } else {
        $success_url = "http://${search.host}:8000"
      }
    }
  }

  # Everything from here on down is pretty similar to what is above with a
  # couple exceptions...
  if $mode in ['testdrive', 'forwarder'] {

    # This automation can support managing multiple Universal Forwarders but
    # only able to confgure for one search/indexer target per invocation
    $forwarders = $mode ? {
      'testdrive' => get_targets('forwarder'),
      default     => get_targets($nodes)
    }

    # This serves two purposes, in forwarder mode we ensure that the
    # deployment_server CLI option takes presedence over search_host and that
    # the search_host parameter provided on the command line overrides the
    # value that is implicitly looked up from the inventory file when running in
    # mode testdrive, e.g. configure Splunk Enterprise through one IP/hostname but
    # configuring your Universal Forwarders to interact with an alternate CNAME
    if $deployment_server and $mode == 'forwarder' {
      $_extra_profile_params = { 'deployment_server'  => $deployment_server }
    } else {
      $_extra_profile_params = {
        'search_host' => pick($search_host, defined('$search') ? {
          true    => $search.name,
          default => undef
        })
      }
    }

    $forwarders.apply_prep

    apply($forwarders) {
      class { 'splunk_qd::profile::forward':
        version           => $version,
        build             => $build,
        passwd_hash       => $passwd_hash,
        manage_addons     => $manage_addons,
        addon_source_path => defined('$addon_source_path') ? { true => $addon_source_path, default => undef },
        addons            => defined('$addons') ? { true => $addons, default => [] },
        *                 => $_extra_profile_params,
      }
    }
  }

  if defined('$success_url') {
    return "Splunk Enterprise is now ready at ${success_url}"
  }
}
