#
# Cookbook Name:: eucalyptus
# Recipe:: osg
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


## Install packages for the OSG
if node["eucalyptus"]["install-type"] == "packages"
  yum_package "eucalyptus-osg" do
    action :upgrade
    options node['eucalyptus']['yum-options']
  end
else
  ## Install CC from source from internal repo if it exists
  execute "export JAVA_HOME='/usr/lib/jvm/java-1.7.0-openjdk.x86_64' && export JAVA='$JAVA_HOME/jre/bin/java' && export EUCALYPTUS='#{node["eucalyptus"]["home-directory"]}' && make && make install" do
    cwd "#{node["eucalyptus"]["source-directory"]}/eucalyptus"
    only_if "ls #{node["eucalyptus"]["source-directory"]}/eucalyptus/clc"
    creates "/etc/init.d/eucalyptus-cloud"
    timeout node["eucalyptus"]["compile-timeout"]
  end
  ## Install CLC from open source repo if it exists
  execute "export JAVA_HOME='/usr/lib/jvm/java-1.7.0-openjdk.x86_64' && export JAVA='$JAVA_HOME/jre/bin/java' && export EUCALYPTUS='#{node["eucalyptus"]["home-directory"]}' && make && make install" do
    cwd "#{node["eucalyptus"]["source-directory"]}"
    only_if "ls #{node["eucalyptus"]["source-directory"]}/clc"
    creates "/etc/init.d/eucalyptus-cloud"
    timeout node["eucalyptus"]["compile-timeout"]
  end
  ### Create symlink for eucalyptus-cloud service
  tools_dir = "#{node["eucalyptus"]["source-directory"]}/tools"
  if node['eucalyptus']['source-repo'].end_with?("internal")
    tools_dir = "#{node["eucalyptus"]["source-directory"]}/eucalyptus/tools"
  end

  execute "ln -s #{tools_dir}/eucalyptus-cloud /etc/init.d/eucalyptus-cloud" do
    creates "/etc/init.d/eucalyptus-cloud"
  end

  execute "chmod +x #{tools_dir}/eucalyptus-cloud"
end

template "#{node["eucalyptus"]["home-directory"]}/etc/eucalyptus/eucalyptus.conf" do
  source "eucalyptus.conf.erb"
  action :create
end

execute "export EUCALYPTUS='#{node["eucalyptus"]["home-directory"]}' && #{node["eucalyptus"]["home-directory"]}/usr/sbin/euca_conf --setup"

service "eucalyptus-cloud" do
  action [ :enable, :start ]
  supports :status => true, :start => true, :stop => true, :restart => true
end
