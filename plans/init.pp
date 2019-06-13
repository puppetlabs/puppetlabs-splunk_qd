# @summary
#   The Bolt Plan here is the primary jumping off point for leveraging the
#   Splunk Quick Deploy module and facilitates orchestrating purpose built tasks
#   and utilizing the **puppet/splunk** module through remote execution of
#   agentless Puppet. The default operating mode of this plan is intended to
#   always be declarative and is designed to follow the roles and profiles
#   pattern for containing and defining interfaces to lower level application
#   specific modules. Since **puppetlabs/splunk_qd** does depend on profiles for
#   abstracting certain aspects of the installation and configuration of  Splunk
#   Enterprise, these profiles can easily be adapted and integrated into a
#   Puppet Enterprise infrastructure-as-code environment to ensure continuous
#   state enforcement.
#
# @see https://puppetlabs.github.io/puppetlabs-splunk_qd
#
# @example Managing Splunk Enterprise and Universal Forwarders
#   bolt plan run splunk_qd
#
# @example Deploying the Universal Forwarder and pointing it at an existing Splunk Enterprise infrastructure
#   bolt plan run splunk_qd search_host=splunk0.example.com
#
# @example Upgrading to a new revision of the Splunk Enterprise and Universal Forwarder
#   bolt plan run splunk_qd version=7.2.6 build=c0bf0f679ce9
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
# @param manage_addons
#   Temporarily disable the management of add-ons when they are defined in your
#   `inventory.yaml` file, add-ons will never be managed if they are not defined
#   within the `inventory.yaml` file
#
# @param manage_forwarders
#   Explicitly disable the management of the Universal Forwarder
#
# @param manage_search
#   Explicitly disable the management of Splunk Enterprise
#
# @param web_ssl
#   To configure Splunk Enterprise Web with SSL and redirect traffic on port 80
#   to 443
#
# @param web_ssl_mode
#   Switch between the two available SSL providers supported by the module
#
# @param web_ssl_reg_email
#   When using the `letsencrypt` SSL provider you must provide an email address
#   to be used as an account that the certificate will be registered to
#
# @param web_ssl_reg_fqdn
#   Sets the common name on the generated and signed certificate when using the
#   `letsencrypt` SSL provider
#
# @param addon_source_path
#   Used for defining a source path that is different than the default in module
#   path
#
# @param forwarder_group
#   Set the inventory group that splunk_qd will source forwarders from
#
plan splunk_qd(
  String[1] $version                                      = '7.2.5',
  String[1] $build                                        = '088f49762779',
  String[1] $forwarder_group                              = 'forwarders',
  Optional[String[1]] $search_host                        = undef,
  Boolean $manage_addons                                  = true,
  Boolean $manage_forwarders                              = true,
  Boolean $manage_search                                  = true,
  Boolean $web_ssl                                        = false,
  Boolean $cloud                                          = false,
  Optional[Enum['internal', 'letsencrypt']] $web_ssl_mode = undef,
  Optional[String[1]] $web_ssl_reg_email                  = undef,
  Optional[String[1]] $web_ssl_reg_fqdn                   = undef,
  Optional[String[1]] $addon_source_path                  = undef,
) {

  # Alwasy look this up since we have a use for the data defined with it even if
  # we do not plan on managing the node and its fine if if returns nil
  $search_head = get_targets('search_head')

  # Conditional to disable search node management
  if $manage_search {

    if $web_ssl {
      $_ssl = merge($search_head[0].vars['ssl'], {
        'mode'      => $web_ssl_mode,
        'reg_email' => $web_ssl_reg_email,
        'reg_fqdn'  => $web_ssl_reg_fqdn,
      }.filter |$setting| { $setting[1] != undef })
    }

    # Ensures the agentless Puppet helper is installed and gathers facts, always
    # have to run the apply_prep function ahead of an apply block even if the
    # helper is installed or most Puppet modules are going to fail since they
    # rely heavily on facts
    $search_head.apply_prep

    # Function informing Bolt that we are going to execute agentless Puppet
    # code on a remote set of nodes
    $manage_search_results = apply($search_head) {

      # Bolt makes it super easy to follow existing best practices and the all
      # great pieces of content found out in out broad ecosystem, as we've done
      # here building a simple profile for manager Splunk Enterprise which in
      # turn utilizes the puppet/splunk module from Voxpupuli and can then be
      # reused again by a full Puppet Enterprise installation capable of
      # continuous enforcement
      class { 'splunk_qd::profile::search':
        version           => $version,
        build             => $build,
        manage_addons     => $manage_addons,
        addon_source_path => defined('$addon_source_path') ? { true => $addon_source_path, default => undef },
        addons            => defined('$addons') ? { true => $addons, default => [] },
        web_ssl           => $web_ssl,
        ssl               => defined('$_ssl') ? { true => $_ssl, default => {} },
      }
    }
    if $manage_search_results.first.report['status'] == 'changed' {
      if $web_ssl {
        if $_ssl['reg_fqdn'] {
          $success_url = "https://${_ssl['reg_fqdn']}"
        } else {
          $success_url = "https://${search_head[0].host}"
        }
      } else {
        $success_url = "http://${search_head[0].host}:8000"
      }
      notice("Splunk Enterprise is now ready at ${success_url}")
    }
  }

  # Everything from here on down is pretty similar to what's above with a couple
  # exceptions...
  if $manage_forwarders {
    if ! defined('$manage_search_results') or $manage_search_results.ok {

      $forwarders = get_targets($forwarder_group)

      # First hecks to see if were running in cloud moe if not will check if
      # search_host was set on the command line and if so prioritizes is value,
      # then copies it into a private variable to be passed into our forwarder
      # profile. If the variable was not set then it attempts to derive it from
      # the search_head object found in the inventory.yaml file.
      if $search_host {
        $_search_host = $search_host
      } else {
        $_search_host = $search_head[0].host
      }


      $forwarders.apply_prep

      apply($forwarders) {
        class { 'splunk_qd::profile::forward':
          version           => $version,
          build             => $build,
          manage_addons     => $manage_addons,
          addon_source_path => defined('$addon_source_path') ? { true => $addon_source_path, default => undef },
          addons            => defined('$addons') ? { true => $addons, default => [] },
          search_host       => $_search_host,
          cloud             => $cloud,
        }
      }
    } else {
      fail_plan('Universal Forwarder configuration skipped due to previous failure configuring Splunk Enterprise')
    }
  }
}
