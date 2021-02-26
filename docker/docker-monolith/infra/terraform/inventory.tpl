[docker]
%{ for i in range(length(names)) ~}
${names[i]} ansible_host=${addrs[i]}
%{ endfor ~}
