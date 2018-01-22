class docker {
	if $operatingsystem == 'Debian' {
		$packages = 'docker-engine'
	}
	elsif $operatingsystem == 'Ubuntu' {
		$dependencies = [ 'apt-transport-https', 'ca-certificates', 'curl', 'software-properties-common' ]
		$packages = 'docker-ce'
		$key = '0EBFCD88'
	}
	elsif $operatingsystem == 'CentOS' {
		$packages = 'docker-engine'
	}

	file { 'docker.list':
  		path => '/etc/apt/sources.list.d/docker.list',
		content => "deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable"
	}

	exec { 'apt-get-update':
		command => '/usr/bin/apt-get update',
		subscribe => File['docker.list'],
		refreshonly => true
	}
	->
	exec { 'apt-key docker':
		path    => '/bin:/usr/bin',
		unless  => "apt-key list | grep '${key}' | grep -v expired",
		command => "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && apt-key fingerprint ${key}",
	}
	->	
	package { $dependencies: ensure => present }
	->
	package { $packages: ensure => present }
	->
	service { 'docker':
		ensure => running,
		hasstatus => true,
		hasrestart => true,
		enable => true,
	}
}
