# Copyright 2015 Thomas Krille
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing
# permissions and limitations under the License.

Puppet::Type.newtype(:container) do
  @doc = 'Create a new container and optionally start it.'

  ensurable
  # ensurable do
  #   desc 'What state the container should be in.'
  #
  #   newvalue(:started) do
  #   end
  #
  #   aliasvalue(:present, :started)
  #
  #   newvalue(:stopped) do
  #   end
  #
  #   newvalue(:removed) do
  #   end
  #
  #   aliasvalue(:absent, :removed)
  #
  #   defaultto :started
  # end

  newparam(:name, :namevar => true) do
    desc 'The name of the container to manage'
  end

  newproperty(:image) do
    desc 'The fully qualified image name to create the container from. Required.'

    validate do |fqin|
      fail('\'image\' must not be empty') if fqin.to_s.empty?
      provider.image_validate fqin.to_s
    end

    munge do |fqin|
      provider.image_munge fqin.to_s
    end
  end

  newproperty(:env) do
    desc 'Environment variables as a Hash'

    validate do |value|
      fail('Parameter \'env\' must be a Hash') unless value.is_a?(Hash)
    end

    def insync?(is)
      should.each do |key, value|
        return false unless is.has_key? key and is[key] == value
      end
      true
    end
  end

  newproperty(:links) do
    desc 'Links to local containers as a Hash'

    validate do |value|
      fail('Parameter \'links\' must be a Hash') unless value.is_a?(Hash)
    end
  end

  newproperty(:volumes, :array_matching => :all) do
    desc 'List of external volumes'

    def insync?(is)
      if is.is_a?(Array) and should.is_a?(Array)
        is.sort == should.sort
      else
        is == should
      end
    end
  end

  newproperty(:hostname) do
    desc 'The hostname of the container'

    validate do |hostname|
      fail('Parameter \'hostname\' must be a String') unless hostname.is_a?(String)
      fail('Parameter \'hostname\' must be a valid hostname') if hostname.empty?
    end
  end

  newproperty(:ports, :array_matching => :all) do
    desc 'Ports to map from the container'

    def insync?(is)
      if is.is_a?(Array) and should.is_a?(Array)
        is.sort == should.sort
      else
        is == should
      end
    end
  end

  newproperty(:user) do
    desc 'The user to run the first process within the container'

    validate do |user|
      fail('Parameter \'user\' must be a String') unless user.is_a?(String)
      fail('Parameter \'user\' must be not empty') if user.empty?
    end
  end

  newproperty(:restart) do
    desc 'The restart policy for failed containers'

    validate do |restart|
      fail 'Parameter \'restart\' must be a String' unless restart.is_a?(String)
      fail 'Parameter \'restart\' must be not empty' if restart.empty?

      provider.restart_validate restart
    end

    munge do |restart|
      provider.restart_munge restart
    end
  end

  newproperty(:network) do
    desc 'The network mode of the container'

    validate do |network_mode|
      fail 'Parameter \'network\' must be a String' unless network_mode.is_a?(String)
      fail 'Parameter \'network\' must be not empty' if network_mode.empty?

      provider.network_validate network_mode
    end
  end

  autorequire(:container) do
    linked = []
    linked = self[:links].keys unless self[:links].nil?

    networked = []
    unless self[:network].nil? or self[:network].empty? or not self[:network].start_with? 'container:'
      networked = [self[:network].split(':', 2)[1]]
    end

    linked.concat networked
  end

  validate do
    fail('\'image\' is required when ensure is \'present\'') if self[:ensure] == :present and self[:image].nil?
    provider.validate
  end

end
