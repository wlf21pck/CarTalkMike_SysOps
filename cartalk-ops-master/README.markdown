# cartalk.ops

Tooling for managing CarTalk infrastructure on AWS.


## First Setup

We use [Ansible](http://docs.ansible.com) so we need a python environment to
work with. For best results on OSX we recommend installing python via
[Homebrew](http://brew.sh):

    $ brew install python
    
Install Ansible:

    $ brew install ansible

Install pip python package mananager:

    $ easy_install pip

Install [virtualenv](https://pypi.python.org/pypi/virtualenv) and create a virtualenv to avoid messing with your system python:

    $ pip install virtualenv
    $ virtualenv venv

Activate the virtualenv:

    $ source venv/bin/activate

Install the necessary dependencies:

	$ pip install -r requirements.txt

## First Access

### .env file

The repository includes an `.env.template` file that should be used as a placeholder for sensitive variables. Update
these with values provided by an existing team member. These credentials are primarily used by ansible modules to
interact with APIs like AWS and Slack. **Please copy the template file `.env.template` to `.env` in the root of the
repository and populate it with the necessary secret tokes.**

To load these variables into your shell:

    $ source .env

**Due to the sensitivity of the information stored in this file, please contact a DevOps or Dev for the right values to
be used.**

### Ansible vault

Sensitive config values are stored in an encrypted ansible vault and checked in to this repository.  **Before you can
deploy you'll need the passphrase for this ansible vault, you can get it from an existing team member.** You can store
this passphrase in a `.vault-password` file within this directory to avoid having to enter it every time you deploy or
edit configuration.

### Bastion host

It is possible to access the AWS boxes only via a specific box called the bastion host (_cartalk-bastion.nirdhost.com_).
To be allowed to access the bastion host a personal SSH key is required. Please send the corresponding public key to a
DevOps to get it deployed on the host and be able to access it.

The rest of the AWS infrastructure can be accessed as the user `barbershop` with a common _cartalk.pem_ key, which can
be found in the home folder of the `barbershop` user on the bastion host. Please be aware that the `barbershop` user has
sudo rights.

For your convenience, a `ssh.config` file has been provided as part of this repository. It can be loaded in conjuction
with any command of the ssh suite.

Once your public key has been deployed on the bastion host you can access it with the following:

    $ ssh-add ~/.ssh/YOUR_PRIVATE_KEY
    $ ssh -F ssh.config -A cartalk-bastion.nirdhost.com
	barbershop@ip-192-168-9-28:~$ ls -l cartalk.pem
	total 4
	-rw------- 1 barbershop barbershop 1679 Jul 20 09:23 cartalk.pem

Copy the cartalk.pem file over to your local machine (scp, sftp or cat) and add it to the ssh agent, along with your personal key (previously added):

    $ scp barbershop@cartalk-bastion.nirdhost.com:~/cartalk.pem ~/.ssh/
    $ ssh-add ~/.ssh/cartalk.pem

OR

    $ ssh -A barbershop@cartalk-bastion.nirdhost.com
    barbershop@ip-192-168-9-28:~$ cat cartalk.pem
    (copy the contents to a local file ~/.ssh/cartalk.pem)

Back on your local machine:

    $ chmod 600 ~/.ssh/cartalk.pem
    $ ssh-add ~/.ssh/cartalk.pem

As an example, let's try to login on the _stageawscartalk01-vpc.cartalk.com_ box:

    $ ssh-add ~/.ssh/YOUR_PRIVATE_KEY
    $ ssh-add ~/.ssh/cartalk.pem
    $ ssh -A barbershop@cartalk-bastion.nirdhost.com
    barbershop@ip-192-168-9-28:~$ ssh ec2-user@stageawscartalk01-vpc.cartalk.com
    [ec2-user@ip-192-168-0-117 ~]$

### SSH access to application instances

* Stage instance: _stageawscartalk1.cartalk.com_
* Production instance us-east-1d: _awscartalk1.cartalk.com_
* Production instance us-east-1e: _awscartalk2.cartalk.com_
* Production admin instance us-east-1d: _awscartalk-admin.cartalk.com_

To connect to one of the above make sure you have your personal key and cartalk key loaded into your SSH Agent and
execute the following command from the root of this repository:

    $ ssh -F ssh.config awscartalk-admin.cartalk.com

## App Architecture and Roles

![](https://github.com/nirds/cartalk-ops/blob/master/CarTalk%20VPC%20Phase%20%232%20-%20VPC%20Architecture.png?raw=true "VPC Architecture Phase #2")

There are four server roles in the current architecture, all of which have been tagged with an EC2 tag named _Role_:

1. **bastion**: there is only one instance with this role. This machine allows SSH access to all the other machines in
   the estate. This box must always be your first administrative hop into the servers.
2. **staging**: there is only one instance with this role. This machine is a webserver that runs the staging version of
   the desktop CarTalk portal against a staging database.
3. **production**: there are several instances with this role. These machines are webservers running both the desktop
   and mobile CarTalk portals.
4. **production-admin**: there is only one instance with this role. This machine act as a regular production webserver
   for both desktop and mobile CarTalk portals; in addition, this instance runs several cron jobs that range from
	   keeping in sync the DocRoots of the production webservers to performing backups of uploaded files and database.
	   This box is also used as the administrative machine for the Drupal panel.

The CarTalk application is based on Drupal, and is currently serverd via a classic Apache _prefork_ with *mod_php*.

## Application Configuration

The Apache configuration for the mentioned VirtualHost is defined inside the _/etc/httpd/conf.d_ folder of the application
servers.

Drupal configuration for the desktop application can be found at _/www/docs/www.cartalk.com/sites/default/settings.php_.

## Ansible Playbooks

This project contains ansible playbooks for deploying each app to its respective environments, as well as playbooks used
to configure servers for all the above roles from the ground up.

The following playbooks are available in this repository:

1. [bastion.yml](https://github.com/nirds/cartalk-ops/blob/master/bastion.yml) - used to configure the bastion host and
   deploy personal public keys on it.
2. [webserver.yml](https://github.com/nirds/cartalk-ops/blob/master/webserver.yml) - used to configure staging,
   production and production-admin webservers, includin monitoring. Please note that only the platform gets configured,
   no actual CarTalk code is deployed with this. It is also possible to configure only a single role out of the
   mentioned. For this, please refer to the "Server and Platform Configuration" section. Several variables can be passed
   to the playbook to customize the configuration.
3. [monit-install.yml](https://github.com/nirds/cartalk-ops/blob/master/monit-install.yml) - used to install _monit_
   monitoring daemon on webservers.
4. [monit-setup.yml](https://github.com/nirds/cartalk-ops/blob/master/monit-setup.yml) - used to push monit check
   configuration files to webservers to actually monitor resources and processes.
5. [deploy-staging.yml](https://github.com/nirds/cartalk-ops/blob/master/deploy-staging.yml) - used to deploy the desktop
   portal _www.cartalk.com_ to the staging environment. It is possible to select what branch or revision to deploy.
   Please note that the _Drush_ Drupal administration tool is installed as part of the deployment.
6. [deploy-production.yml](https://github.com/nirds/cartalk-ops/blob/master/deploy-production.yml) - used to deploy the 
   portal _www.cartalk.com_ to the production environment. It is possible to select
   what branch or revision to deploy. Please note that the _Drush_ Drupal administration tool is installed as part of
   the deployment.

### Local Prerequisites

Before using the Ansible playbooks included in this repository, please make sure that you have followed all the steps of
the previous sections "First Setup" and "First Access".

After opening a terminal at the root of the _cartalk-ops_ repo, the following steps are required to setup your environment
**each time** you want to run a playbook:

    $ source .env
    $ source venv/bin/activate
    $ ssh-add ~/.ssh/YOUR_PRIVATE_KEY
    $ ssh-add ~/.ssh/cartalk.pem

### Server and Platform Configuration

As an example, let's try to roll the _webserver.yml_ playbook to create a operational web server from scratch for a
'staging' environment.

	$ ansible-playbook -l tag_Role_staging webserver.yml

Please note that it is necessary to filter the hosts we are applying the playbook to with the _-l_ switch since the
playbook is coded to roll out the changes on the _production_ and _production-admin_ roles as well.

The playbook will install and configure Apache, mod\_php, some basic PHP extensions, PHP APC Caching system and monit.
This playbook will ensure all the platform's bit and pieces are in place, ready to deploy the CarTalk codebase.

### Deployment

The deployment playbooks will take care of fetch and checkout the CarTalk codebase onto the WebServer instances, making
sure all the prerequisites for a correct deployment are met.

The Ansible code will take care of the following:

1. Create essential folders under _/www_ and _/var/log_.
2. Install _cronolog_ for Apache's log rotation.
3. Apply _stage.cartalk.com_ or _www.cartalk.com_ Apache's configuration.
4. Ensure Apache's DocumentRoot folders exist.
5. Create _DONOTREMOVE.php_ healthcheck file in the DocRoot.
6. Install _Drush_ Drupal administration toool.
7. Install git.
8. Upload SSH deploy key to the server.
9. Put the site into maintenance mode and clear the cache.
10. Clone CarTalk repository and check out specified branch or revision.
11. If _sites/default/files_ does not exist, obtain and extract the latest backup from S3.
12. Restart Apache.
13. Disable maintenance mode and clear the cache.


#### Staging

To deploy to the staging environment, it is sufficient to launch the the deploy-staging.yml playbook with an optional
_branchname_ variable. Branch will default to _stage_ if not specified.

    $ ansible-playbook deploy-staging.yml [-e branchname=v1.1]


This will deploy _www.cartalk.com_ codebase to the staging environment.


#### Production

To deploy to the production environment, it is sufficient to launch the the deploy-production.yml playbook with an optional
_branchname_ and / or *mobile_branchname* variable. Branch will default to _master_ if not specified.

    $ ansible-playbook deploy-production.yml [-e branchname=v1.1] [-e mobile_branchname=master]


This will deploy _www.cartalk.com_ to the production environment.
