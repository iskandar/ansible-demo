#!/usr/bin/env python
from __future__ import print_function
import pyrax
import os

# Authenticate
pyrax.set_setting("identity_type", "rackspace")
pyrax.set_setting("region", os.environ.get('OS_REGION', "LON"))
pyrax.set_credentials(os.environ.get('OS_USERNAME'), os.environ.get('OS_API_KEY'))

# Set up some aliases
au = pyrax.autoscale

# Consume our environment vars
environment_name = os.environ.get('ENVIRONMENT_NAME', '')
policy_name = os.environ.get('POLICY_NAME', 'scale-to-02')

# Try to find the ASG by naming convention.
# This is brittle and we should be rummaging in the launch_configuration metadata
filtered = (node for node in au.list() if
            node.name == '' + environment_name + '-asg')

sg = None
for asg in filtered:
    sg = asg
    break

policy_gen = (policy for policy in sg.list_policies() if
    policy.name == policy_name)

for policy in policy_gen:
    print("Executing Policy: ", policy.name, policy.id)
    policy.execute()
