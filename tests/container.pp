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

container { 'test':
  ensure => present,
  image  => 'test:latest',
  hostname => 'test',
  user => 'nobody',
  restart => 'on-failure:10',
  env    => {
    'TEST' => 'some value',
    'TEST_2' => 'some other value',
  },
  links => {
    'test2' => 'link1',
    'test3' => 'link2',
  },
  volumes => [
    '/test-anon',
    '/tmp:/test-host',
    '/tmp:/test-host-expl-rw:rw',
    '/tmp:/test-host-ro:ro',
  ],
  ports => [
    '8080',
    '18080:8080',
    '127.0.0.1:19090:9090',
    '127.0.0.1::9090',
    '0.0.0.0:17070:7070',
  ],
}

container { 'test2':
  ensure => present,
  image  => 'test:latest',
  hostname => 'test2',
  restart => 'always',
  env    => {
    'TEST' => 'some value',
  },
  volumes => ['/tmp:/test-host'],
  ports => ['28080:8080'],
}

container { 'test3':
  ensure => present,
  image  => 'test:latest',
  env    => {
    'TEST' => 'some value',
  },
  volumes => '/test-anon',
  ports => '8080',
}
