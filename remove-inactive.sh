#!/bin/bash

# This script is targeting a Puppet Enterprise 3.8.1 host.  Nodes that were deactivated from
# PuppetDB were still showing up in the console

# This gets a list of console hosts  outputs to /tmp/console.out
/opt/puppet/bin/rake -f /opt/puppet/share/puppet-dashboard/Rakefile \
RAILS_ENV=production node:list 1>/tmp/console.out 2>/dev/null

# This gets a clean output of nodes in PuppetDB  output to /tmp/pdb.out
curl -X GET https://`puppet config print server`:8081/v3/nodes \
--cacert `puppet config print localcert` \
--cert `puppet config print hostcert` \
--key  `puppet config print localcert` \
--insecure --silent|grep name|awk '{print $3}'|sed 's/"//'|sed 's/",//' >> /tmp/pdb.out

# Diff the output files only reporting hosts listed in console only (deactive hosts
diff --suppress-common-lines /tmp/console.out /tmp/pdb.out |awk '{print $2}' > /tmp/diff.out

# Spin through output and delete the nodes from the console
for node in `cat /tmp/diff.out`
  do
    /opt/puppet/bin/rake -f /opt/puppet/share/puppet-dashboard/Rakefile \
    RAILS_ENV=production node:del[$node]
  done
