# encoding: UTF-8
#
# Author:: Xabier de Zuazo (<xabier@onddo.com>)
# Copyright:: Copyright (c) 2014 Onddo Labs, SL. (www.onddo.com)
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

require 'spec_helper'

describe 'onddo_proftpd::ohai_plugin' do
  let(:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }

  it 'should install proftpd plugin' do
    expect(chef_run).to create_template('/etc/chef/ohai_plugins/proftpd.rb')
      .with_owner('root')
      .with_group('root')
      .with_mode('0755')
  end

  it 'proftpd plugin installation should notify ohai reload' do
    resource = chef_run.template('/etc/chef/ohai_plugins/proftpd.rb')
    expect(resource).to notify('ohai[reload_proftpd]').to(:reload).immediately
  end

  context 'with Ohai 6' do
    before do
      stub_const('Ohai::VERSION', '6.24.2')
    end

    it 'should use the template from plugins/' do
      expect(chef_run).to create_template('/etc/chef/ohai_plugins/proftpd.rb')
        .with_source('plugins/proftpd.rb.erb')
    end
  end # context with Ohai 6

  context 'with Ohai 7' do
    before do
      stub_const('Ohai::VERSION', '7.0.0')
    end

    it 'should use the template from plugins7/' do
      expect(chef_run).to create_template('/etc/chef/ohai_plugins/proftpd.rb')
        .with_source('plugins7/proftpd.rb.erb')
    end
  end # context with Ohai 6

  it 'should include ohai::default recipe' do
    expect(chef_run).to include_recipe('ohai::default')
  end
end
