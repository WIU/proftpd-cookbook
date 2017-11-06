# encoding: UTF-8
#
# Cookbook Name:: onddo_proftpd
# Recipe:: default
# Author:: Xabier de Zuazo (<xabier@zuazo.org>)
# Copyright:: Copyright (c) 2014 Onddo Labs, SL.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Ohai Plugin
ohai_plugin 'proftpd' do
  source_file 'proftpd.rb.erb'
  resource :template
end

include_recipe 'yum-epel' if platform?('redhat', 'centos', 'amazon')

#
# Install required packages
#

package 'proftpd'

if node['proftpd']['conf']['if_module']['dso']['load_module'].include?('dso')
  node['proftpd']['conf']['if_module']['dso']['load_module'].uniq.each do |mod|
    packages = node['proftpd']['module_packages'][mod]
    next unless packages.is_a?(Array)
    packages.each do |pkg|
      package pkg do
        notifies :reload, 'service[proftpd]'
      end # package
    end # package.each
  end # ['dso']['load_module'].each
end # include?('dso')

# Create the required directories

directory '/etc/proftpd'

node['proftpd']['conf']['include'].each do |dir|
  directory dir
end

#
# Create configuration files
#

# Create an empty modules.conf file to avoid update errors on Debian
template '/etc/proftpd/modules.conf' do
  user node['proftpd']['conf_files_user']
  group node['proftpd']['conf_files_group']
  mode node['proftpd']['conf_files_mode']
end

template '/etc/proftpd/proftpd.conf' do
  user node['proftpd']['conf_files_user']
  group node['proftpd']['conf_files_group']
  mode node['proftpd']['conf_files_mode']
  variables(
    # compiled_in_modules: node['proftpd']['compiled_in_modules'],
    conf: node['proftpd']['conf']
  )
  notifies :restart, 'service[proftpd]'
end

link '/etc/proftpd.conf' do
  to '/etc/proftpd/proftpd.conf'
  notifies :restart, 'service[proftpd]'
end

service 'proftpd' do
  supports restart: true, reload: true, status: true
  action [:enable, :start]
end
