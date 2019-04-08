
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

The premise of the module is to provide a facility for bringing online new instances of Splunk Enterprise with the option to import data from production deployments that enables people to evalate the product, do application and addon development, or test a major upgrade. To make sure usage is as simple as possible and we can implement a complete deployment workflow, we have chosen to focus on Puppet Bolt as opposed to purely classic Puppet. We'll re-use and depend on the Voxpupuli puppet-splunk module when ever appropriate so that any installation ininitially deployed through this method can be promoted to a production install and continuously maintained by Puppet safely and without many changes if any at all.

This means that what you'll find in this module is a collection of Bolt Plans that'll deploy different components of a Splunk Enterprise environment that applies Puppet manifests using Bolt's agentless apply functionality with some glue in between that might not fit well into Puppet's preference for managing desired state but is really only applicable for the use case of rapid initial deployment.

## Setup

### What splunk_qd affects

It is not intended for this module to take over management of existing Splunk Enterprise installations but some exist that might interact with a living installation or the plans are generic enough that they could be repurposed, e.g. facilitating the backing up of indexes to be restored for the purpose of testing and development or onboarding and upgrading the universal forwarder.

### Setup Requirements

Right now the module includes addons downloaded from splunkbase and tar file of sample data, both of these will be removed soon and only exist to assist in the intial prototyping process. It is the intention that the use must download these files ahead of time and place them is the right place before running the corresponding plan.

### Beginning with splunk_qd

The quickest way to get started is by adapting the included sample inventory file and simply running `bolt plan run splunk_qd` which will install an all-in-one Splunk Enterprise server with addons and point a set of nodes at the instance to begine forwarding logs.

## Usage

Nothing yet...example text kept for my own reference

Include usage examples for common use cases in the **Usage** section. Show your users how to use your module to solve problems, and be sure to include code examples. Include three to five examples of the most important or common tasks a user can accomplish with your module. Show users how to accomplish more complex tasks that involve different types, classes, and functions working in tandem.

## Limitations

Be design we are dependent on the puppet-splunk module so limitied to the deployment targets is supports and must adhere to its opinions on search head, indexer, and forwarder configuration

## Development

Contributions welcome just know that you should focus on the Puppet 5 syntax available in a default intallation of the latest release of Bolt and the code cannot depend on the existance of a master or puppetdb.
