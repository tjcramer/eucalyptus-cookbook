#
# Cookbook Name:: eucalyptus
# Recipe:: install-first-resources
#
#Copyright [2014] [Eucalyptus Systems]
##
##Licensed under the Apache License, Version 2.0 (the "License");
##you may not use this file except in compliance with the License.
##You may obtain a copy of the License at
##
##    http://www.apache.org/licenses/LICENSE-2.0
##
##    Unless required by applicable law or agreed to in writing, software
##    distributed under the License is distributed on an "AS IS" BASIS,
##    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
##    See the License for the specific language governing permissions and
##    limitations under the License.
##
#
execute "Add keypair: my-first-keypair" do
  command "source #{node['eucalyptus']['admin-cred-dir']}/eucarc && euca-create-keypair my-first-keypair >/root/my-first-keypair && chmod 0600 /root/my-first-keypair"
  not_if "source #{node['eucalyptus']['admin-cred-dir']}/eucarc && euca-describe-keypair my-first-keypair"
end

execute "Authorizing SSH and ICMP traffic for default security group" do
  command "source #{node['eucalyptus']['admin-cred-dir']}/eucarc && euca-authorize -P icmp -t -1:-1 -s 0.0.0.0/0 default && euca-authorize -P tcp -p 22 -s 0.0.0.0/0 default"
end

execute "Install default image" do
  command "source #{node['eucalyptus']['admin-cred-dir']}/eucarc && export EUSTORE_URL=#{node["eucalyptus"]["eustore-url"]} && eustore-install-image -b my-first-image -i $(eustore-describe-images | egrep \"#{node["eucalyptus"]["default-image"]}.*kvm\" | head -1 | cut -f 1)"
  not_if "source #{node['eucalyptus']['admin-cred-dir']}/eucarc && euca-describe-images | grep emi"
end

execute "Ensure default image is public" do
  command "source #{node['eucalyptus']['admin-cred-dir']}/eucarc && euca-modify-image-attribute -l -a all $(euca-describe-images | grep my-first-image | grep emi | awk '{print $2}')" 
end

execute "Wait for resource availability" do
  command "source #{node['eucalyptus']['admin-cred-dir']}/eucarc && euca-describe-availability-zones verbose | grep m1.small | grep -v 0000"
  retries 50
  retry_delay 10
end

execute "Running an instance" do
  command "source #{node['eucalyptus']['admin-cred-dir']}/eucarc && euca-run-instances -k my-first-keypair $(euca-describe-images | grep my-first-image | grep emi | cut -f 2)"
end
