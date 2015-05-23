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

container { 'network-bridge':
  ensure => present,
  image  => 'test:latest',
  network => 'bridge',
}

container { 'network-container':
  ensure => present,
  image  => 'test:latest',
  network => 'container:network-container-target',
}

container { 'network-container-target':
  ensure => present,
  image  => 'test:latest',
}

container { 'network-host':
  ensure => present,
  image  => 'test:latest',
  network => 'host',
}

container { 'network-none':
  ensure => present,
  image  => 'test:latest',
  network => 'none',
}
