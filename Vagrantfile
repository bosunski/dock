# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Use Ubuntu 22.04 LTS
  config.vm.box = "ubuntu/jammy64"
  
  # Configure VM resources
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = 2
    vb.name = "dock-test-server"
  end
  
  # Network configuration
  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "forwarded_port", guest: 443, host: 8443
  config.vm.network "forwarded_port", guest: 22, host: 2222, id: "ssh"
  
  # Sync folders
  config.vm.synced_folder ".", "/vagrant"
  
  # Hostname
  config.vm.hostname = "dock-test"
  
  # Provisioning message
  config.vm.post_up_message = <<-MSG
    ╔═══════════════════════════════════════════════════════╗
    ║  Dock Test Server is ready!                           ║
    ║                                                        ║
    ║  Test your Ansible playbooks with:                    ║
    ║  cd infra && ansible-playbook -i inventory/hosts.yml \\ ║
    ║     playbook.yml --limit local                        ║
    ║                                                        ║
    ║  Access services at:                                  ║
    ║  - HTTP: http://localhost:8080                        ║
    ║  - HTTPS: https://localhost:8443                      ║
    ║  - SSH: ssh -p 2222 vagrant@localhost                 ║
    ║                                                        ║
    ║  Default password: vagrant                            ║
    ╚═══════════════════════════════════════════════════════╝
  MSG
  
  # Optional: Run Ansible provisioning automatically
  # Uncomment to auto-provision on vagrant up
  # config.vm.provision "ansible" do |ansible|
  #   ansible.playbook = "infra/playbook.yml"
  #   ansible.inventory_path = "infra/inventory/hosts.yml"
  #   ansible.limit = "local"
  # end
end
