
# splunk_qd (Splunk Quick Deploy)

Lightning-fast deployment of Splunk for simple testing and evaluation.

This code is experimental and unsupported but is in recently development and rests upon the strong foundation of a production-grade module, the Puppet Approved [puppet/splunk](https://forge.puppet.com/puppet/splunk) maintained by [Vox Pupuli](https://voxpupuli.org).

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with splunk_qd](#setup)
   * [What splunk_qd affects](#what-splunk_qd-affects)
   * [Setup requirements](#setup-requirements)
   * [Beginning with splunk_qd](#beginning-with-splunk_qd)
3. [Usage - Configuration options and additional functionality](#usage)
   * [Scenario 1](#scenario-1)
   * [Scenario 2](#scenario-2)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)

## Description

The premise of the module is to provide a facility for bringing online new instances of Splunk Enterprise with the option of independently managing the Universal Forwarder, install add-ons for the purpose of development, testing major upgrades, of product evaluation. To make sure usage is as simple as possible and we can implement a complete deployment workflow, we have chosen to focus on Puppet Bolt as opposed to classic Puppet. We'll re-use and depend on the Vox Pupuli puppet-splunk module when ever appropriate so that any installation initially deployed through this method can be promoted to a production install and continuously maintained by Puppet safely and without many changes if any.

This means that what you'll find in this module is a Bolt Plan that will deploy different components of a Splunk Enterprise environment by applying Puppet manifests using Bolt's agentless functionality with some glue in between that might not fit well into Puppet's preference for managing desired state but is really only applicable for the use case of rapid initial deployment.

## Setup

### What splunk_qd affects

It is not intended for this module to take over management of existing Splunk Enterprise installations but some functions can co-exist with a living installation and the plans are generic enough that they could be repurposed, e.g. only onboarding and upgrading the Universal Forwarder.

### Setup Requirements

It is required that you have an account on splunkbase and are able to obtain add-on or app archives from it if you desire to use splunk_qd to install them, there is no way to automate fetching them from splunkbase. The module does through include two add-ons, one for Linux/Unix and another for Windows with the intention of providing fully encompassing test drive experience for new users of Splunk Enterprise.

### Beginning with splunk_qd

In all cases you need to have installed and be familiar with [Puppet Bolt](https://puppet.com/docs/bolt/latest/bolt.html) and have SSH and WinRM access to hosts and you have administrative privileges on them so you can run escalated commands. Its recommended that you start with a fresh Bolt [project directory](https://puppet.com/docs/bolt/latest/bolt_project_directories.html#project-directories) since the contents of the `inventory.yaml` file can be highly specific if you plan on deploying a full test drive oriented deployment for evaluation. An example `Puppetfile` can be found in the module's example's directory, the modules listed in the example `Puppetfile` are the minimum requirements for splunk_qd. Once you've copied or integrated the example `Puppetfile` into your project directory, you run `bolt puppetfile install` to populate your project directory's modules sub-directory with all the defined dependencies.

## Usage

#### Scenario 1

**Description:** I have an existing Splunk Enterprise infrastructure and would like to automate the deployment and configuration of a specific version of the Splunk Universal Forwarder on a set of nodes.

**Steps:**

1. Run the splunk_qd plan and provide a list of targets and the deployment_server parameter to configure nodes to retrieve add-on configurations from an existing fully configured instance of Splunk Enterprise

    `bolt plan run splunk_qd deployment_server=splunk.example.com --targets db1.example.com,web5.example.com,dns3.example.com`

#### Scenario 2

**Description:** I want to deploy and configure a set of nodes running the Splunk Universal Forwarder to send the data captured by the **Splunk Add-On for Microsoft Windows** and **Splunk Add-On for Unix and Linux** to a freshly deployed installation of Splunk Enterprise so I can evaluate the software.

**Steps:**

1. In your CLI of choice, browse to the splunk_qd repository you’ve downloaded or cloned from GitHub. 
2. Run `bolt —version` to validate that Bolt is installed successfully. This guide validated on version 1.37.0 but any recent version of Bolt should work with this guide. 
3. Run `bolt puppetfile install` and Bolt will install all the Forge content necessary to complete this guide into Boltdir/modules, referencing the Puppetfile in the Boltdir. 
4. Next, we’ll tell Bolt which machines to work with using any number of inventory targets. If you already have infrastructure suitable for deploying Splunk, copy `Boltdir/examples/inventory.yaml` to `Boltdir/inventory.yaml` and continue to the next step. 
Alternatively, if you’re a Terraform user, you’ll find an example .tf Plan and integrated Bolt inventory.yaml in `Boltdir/examples/terraform`. Copy `Boltdir/examples/terraform/inventory.yaml` to `Boltdir/inventory.yaml` and continue to the next step. 
5. Open `Boltdir/inventory.yaml` in your editor of choice. 
6. Modify *config.ssh.user* to the correct login user for your hosts
7. Modify *config.winrm.user* to the correct login user for your hosts
8. Modify *config.winrm.password* to the correct login password for your hosts
9. Set the value of *groups.name['search'].targets* to the fully qualified domain name or IP address of the node you want to install Splunk Enterprise on
10. Find the nested *targets* parameter under *groups.name[‘forwarder’].groups.name[‘linux_forwarders’]* and modify the array of nodes so it contains the fully qualified domain name or IP addresses for the Linux nodes you wish to manage the Splunk Universal Forwarder on
11. Find the nested *targets* parameter under *groups.name[‘forwarder’].groups.name[‘windows_forwarders’]* and modify the array of nodes so it contains the fully qualified domain name or IP addresses for the Windows nodes you wish to manage the Splunk Universal Forwarder on
12. The example `inventory.yaml` file we started with has an *addons* variable set within each group, which is where add-on installation is defined and it currently setup to source add-ons for both sets of nodes from within the module
13. After you’ve made you configuration changes, write and close `inventory.yaml`
14. Now you should be ready to run the following command:
    `bolt plan run splunk_qd mode=testdrive`
15. After a couple of minutes, Bolt should have successfully deployed Splunk Enterprise, configured apps and add-ons, and connected other infrastructure to Splunk by deploying forwarders. Visit the FQDN of the machine you associated with the search group in step 9 on port `8000` to login with the stock default admin/changeme login. 
16. Well done! You’ve successfully automated the deployment of Splunk Enterprise in minutes. The Bolt Plan underpinning this guide supports SSL configurations with LetsEncrypt, password management, and other options for enterprise deployments. Have a look at the Plan documentation and play around with specifying different options using `bolt plan run splunk_qd param=value`. 

#### Scenario 3

**Description:** I want to deploy and configure a set of nodes running the Splunk Universal Forwarder to send the data captured by a set of add-ons and apps of my choosing to a freshly deployed installation of Splunk Enterprise so I can evaluate the software.

**Steps:**

1. Follow steps 1 through 8 of Scenario 2
2. The example `inventory.yaml` file we started with has an *addons* variable set within each group, which is where add-on installation is defined and is originally setup to source add-ons for both sets of nodes from within the module but in this scenario you're only going to use that for guidance and instead obtain you own add-ons
3. To install add-ons you must first obtain them from [splunkbase](https://splunkbase.splunk.com/) in .tgz format, the add-ons used in the example `inventory.yaml` are [Splunk Add-on for Unix and Linux](https://splunkbase.splunk.com/app/833/) and [Splunk Add-on for Microsoft Windows](https://splunkbase.splunk.com/app/742/)
4. Once you've downloaded add-ons you need to discover their installation name, this is done by expanding the .tgz archive and opening the `app.manifest` within the resulting directory and noting the value of *info.id.name*
5. That installation name for the **Splunk Add-on for Unix and Linux** obtained in step 3 can be found on line 27 of the example `inventory.yaml`, it is set to **Splunk_TA_nix** and you'll find similar on line 53, **Splunk_TA_windows**
6. Once you know your add-ons' installation name and have set it as the value of *name*, set the *filename* key to the name of the original archive downloaded from splunkbase for Linux based add-ons but before doing this for Windows add-ons, re-archive them as .zip archives because the .tgz format is not well supported on Windows
7. Configure inputs by adding entries into the *inputs* hash, each add-on input is a hash of input name and sub-hash of settings, keys being the setting and values being what the setting should be set to. (**DON'T STOP HERE:** There are a couple more steps below the following example)

    **Example**

    The following entry from `inputs.conf`:

    ```
    [monitor:///var/log]
    whitelist = (\.log|log$|messages|secure|auth|mesg$|cron$|acpid$|\.out)
    blacklist = (lastlog|anaconda\.syslog)
    disabled = false
    ```

    Becomes the following when converted to the `inventory.yaml` format:

    ```
    monitor:///var/log:
      whitelist: (\.log|log$|messages|secure|auth|mesg$|cron$|acpid$|\.out)
      blacklist: (lastlog|anaconda\.syslog)
      disabled:  false
    ```
8. After you've configured all your add-ons and inputs, write and close `inventory.yaml`
9. Copy the add-on archive(s) to `$boltdir/modules/splunk_qd/files/addons/`
10. Now you should be ready to run the following command:

    `bolt plan run splunk_qd mode=full`

##### Provisioning

If you are familiar with and keen on Terraform then you'll find the manifests I used when developing Scenario 2 and 3 in the examples/terraform directory, as well as a sample inventory.yaml that uses the Terraform inventory plugin

## Limitations

By design we are dependent on the puppet-splunk module so limited to the deployment targets is supports and must adhere to its opinions on search head, indexer, and forwarder configuration

## Development

All contributions should adhere to Puppet 5 or a greater compatible syntax and best practices and work when executed through the latest release of Puppet Bolt, in addition code cannot depend on the existence of a puppet server or puppetdb.
