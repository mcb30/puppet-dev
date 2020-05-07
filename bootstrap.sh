#!/bin/sh

set -e
set -x

# Install r10k
#
PATH=/opt/puppetlabs/puppet/bin:$PATH gem install r10k

# Temporarily install dependent modules locally
#
PATH=/opt/puppetlabs/puppet/bin:$PATH r10k puppetfile install -v

# Apply the ud::role::puppet::master manifest
#
puppet apply --modulepath=`pwd`/site:`pwd`/modules \
       --hiera_config `pwd`/hiera-bootstrap.yaml \
       -e "include ud::role::puppet::master" -v

# Deploy environment via r10k
#
r10k deploy environment -p

# Check that manifest can be applied without a custom modulepath
#
puppet apply -e "include ud::role::puppet::master" -v
