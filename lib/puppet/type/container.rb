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

  autorequire(:container) do
    self[:links].keys unless self[:links].nil?
  end

  validate do
    fail('\'image\' is required when ensure is \'present\'') if self[:ensure] == :present and self[:image].nil?
    provider.validate
  end

end
