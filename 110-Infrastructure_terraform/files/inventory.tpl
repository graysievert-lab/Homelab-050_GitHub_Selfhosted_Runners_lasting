all:
  hosts:
%{ for hostname in split("\n", hostnames) ~}
    ${hostname}:
      ansible_host: ${hostname}.lan
      ansible_user: rocky
%{ endfor ~}