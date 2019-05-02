
# splunk_qd (Splunk Quick Deploy)

Quick and simple deployment of Splunk for testing and evaulation.

Module still early in development so goals and code will be changing wildly.

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with splunk_qd](#setup)
* [What splunk_qd affects](#what-splunk_qd-affects)
* [Setup requirements](#setup-requirements)
* [Beginning with splunk_qd](#beginning-with-splunk_qd)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)

## Description

The premise of the module is to provide a facility for bringing online new instances of Splunk Enterprise with the option to import data from production deployments that enables people to evalate the product, do application and addon development, or test a major upgrade. To make sure usage is as simple as possible and we can implement a complete deployment workflow, we have chosen to focus on Puppet Bolt as opposed to purely classic Puppet. We'll re-use and depend on the Voxpupuli puppet-splunk module when ever appropriate so that any installation initially deployed through this method can be promoted to a production install and continuously maintained by Puppet safely and without many changes if any at all.

This means that what you'll find in this module is a collection of Bolt Plans that'll deploy different components of a Splunk Enterprise environment that applies Puppet manifests using Bolt's agentless apply functionality with some glue in between that might not fit well into Puppet's preference for managing desired state but is really only applicable for the use case of rapid initial deployment.

## Setup

### What splunk_qd affects

It is not intended for this module to take over management of existing Splunk Enterprise installations but some exist that might interact with a living installation or the plans are generic enough that they could be repurposed, e.g. facilitating the backing up of indexes to be restored for the purpose of testing and development or onboarding and upgrading the universal forwarder.

### Setup Requirements

It is required that you have an account on splunkbase are are able to obtain add-on or app archives from it if you desire to use splunk_qd to install them, there is no way to automate fetching them from splunkbase.

### Beginning with splunk_qd
In all cases you need to have installed and be familiar with [Puppet Bolt](https://puppet.com/docs/bolt/latest/bolt.html) and have SSH access to hosts that you have sudo privileges on so you can run commands as root. Its recommended that you start with a fresh Bolt [project directory](https://puppet.com/docs/bolt/latest/bolt_project_directories.html#project-directories) since the contents of the inventory.yaml file are specific to the plan to be executed. In addition you must add this module **puppetlabs/splunk_qd** and at least the `820a15b` commit of **puppet/splunk** to your project directory `Puppetfile` and run `bolt puppetfile install` to populate your project directory's modules sub-directory.

```
mod 'puppet-splunk', git: 'https://github.com/voxpupuli/puppet-splunk.git', ref: '820a15b'
mod 'puppetlabs-splunk_qd', git: 'https://github.com/puppetlabs/puppetlabs-splunk_qd.git', ref: 'master'
```

## Usage

#### Scenario 1

**Description:** I have an existing Splunk Enterprise infrastructure and would like to automate the deployment and configuration of the Splunk Universal Forwarder on a set of nodes.

**Steps:**

1. Copy `$boltdir/modules/splunk_qd/examples/inventory/forwarders.yaml` to `$boltdir/inventory.yaml`
2. Open `inventory.yaml` for editing
3. Modify *config.ssh.user* to the correct login user for your hosts
4. Modify the array of nodes so it correspond to the fully qualified domain names or IP addresses for the nodes you wish to manage
5. Modify the forwarders group to ensure all node names or aliases have been added
6. The example `inventory.yaml` file has an *addons* variable set under the *forwarders* group which contains a hash of add-ons to be configured when the forwarder is installed, it is safe to delete the variable and you can skip to step 13 if you wish to **ONLY** install the forwarder will configure add-ons in a different way later
7. To install add-ons you must first obtain them from [splunkbase](https://splunkbase.splunk.com/) in .tgz format, the add-on used in the example `inventory.yaml` is [Splunk Add-on for Unix and Linux](https://splunkbase.splunk.com/app/833/)
8. Once you've downloaded the add-on you need to discover its installation name, this is done by expanding the .tgz archive and opening the `app.manifest` within the resulting directory and noting the value of *info.id.name*
9. That installation name for the **Splunk Add-on for Unix and Linux** obtained in step 7 can be found on line 31 of the example `inventory.yaml`, it is set to **Splunk_TA_nix**
10. Once you know your add-on's installation name and have set it as the value of *name*, set the *filename* key to the name of the original archive downloaded from splunkbase
11. Configure inputs by adding entries into the *inputs* hash, each add-on input is a hash of input name and sub-hash of settings, keys being the setting and values being what the setting should be set to. (**DON'T STOP HERE:** There are a couple more steps below the following example)

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
12. After you've configured all your add-ons and inputs, write and close `inventory.yaml`
13. Copy the original add-on archive(s) previously obtained from splunkbase to `$boltdir/modules/splunk_qd/files/addons/`
14. Now you should be ready to run the following command:

`bolt plan run splunk_qd manage_search=false search_host=fqdn_of_splunk_enterprise_server`

#### Scenario 2

**Description:** I want to deploy and configure a fresh installation of Splunk Enterprise and configure a set of nodes running the Splunk Universal Forwarder to send their generaged machine data to the fresh install.

**Steps:**

1. Copy `$boltdir/modules/splunk_qd/examples/inventory/both.yaml` to `$boltdir/inventory.yaml`
2. Open `inventory.yaml` for editing
3. Modify *config.ssh.user* to the correct login user for your hosts
4. Find the node with the *alias* **search_head** and update the name to be the fully qualified domain name or IP address of the node you want to install Splunk Enterprise onto
5. Additionally modify the array of nodes so it also contains the fully qualified domain name or IP addresses for the nodes you wish to manage the Splunk Universal Forwarder on
6. The example `inventory.yaml` file has an *addons* variable set under the **search_head** node and the **forwarders** group which contains a hash of add-ons or apps to be configured when the either is installed, it is safe to delete the variable and you can skip to step 15 if you wish to **ONLY** install the software and will configure add-ons and apps in a different way later
7. To install add-ons or apps you must first obtain them from [splunkbase](https://splunkbase.splunk.com/) in .tgz format, the add-ons used in the example `inventory.yaml` is [Splunk Add-on for Unix and Linux](https://splunkbase.splunk.com/app/833/) and the app is the [Splunk App for Unix and Linux](https://splunkbase.splunk.com/app/273/)
8. Once you've downloaded the ether an add-on or app you need to discover its installation name, this is done by expanding the .tgz archive and opening the `app.manifest` within the resulting directory and noting the value of *info.id.name*
9. That installation name for the **Splunk Add-on for Unix and Linux** obtained in step 7 can be found on line 14 and 49 of the example `inventory.yaml`, it is set to **Splunk_TA_nix**
10. That installation name for the **Splunk App for Unix and Linux** obtained in step 7 can be found on line 26 of the example `inventory.yaml`, it is set to **splunk_app_for_nix**
11. Once you know your add-on and app's installation name and have set it as the value of *name*, set the *filename* key to the name of the original archive downloaded from splunkbase
12. Configure inputs by adding entries into the *inputs* hash, each add-on input is a hash of input name and sub-hash of settings, keys being the setting and values being what the setting should be set to. (**DON'T STOP HERE:** There are a couple more steps below the following example)

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
13. After you've configured all your add-ons, apps, and inputs, write and close `inventory.yaml`
14. Copy the original add-on and app archive(s) previously obtained from splunkbase to `$boltdir/modules/splunk_qd/files/addons/`
15. Now you should be ready to run the following command:

`bolt plan run splunk_qd`

## Limitations

By design we are dependent on the puppet-splunk module so limitied to the deployment targets is supports and must adhere to its opinions on search head, indexer, and forwarder configuration

## Development

All contributions should adhere to Puppet 5 or a greater compatible syntax and best practices and work when executed throught the latest release of Puppet Bolt, in addition code cannot depend on the existance of a puppet server or puppetdb.
