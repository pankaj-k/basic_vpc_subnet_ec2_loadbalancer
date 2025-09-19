#!/bin/bash -x
yum update -y

cat <<EOT1 >> /etc/yum.repos.d/logstash.repo
[logstash-9.x]
name=Elastic repository for 9.x packages
baseurl=https://artifacts.elastic.co/packages/9.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOT1

yum install logstash -y
mkdir -p /home/logstash/data
mkdir -p /home/logstash/conf
mkdir -p /home/logstash/logs
mkdir -p /home/logstash/pipelines
mkdir -p /home/logstash/tmp
chown -R logstash:logstash /home/logstash
sed -i 's|path.data: /var/lib/logstash|path.data: /home/logstash/data|' /etc/logstash/logstash.yml
sed -i 's|path.logs: /var/log/logstash|path.logs: /home/logstash/logs|' /etc/logstash/logstash.yml
sed -i 's|# pipeline.ordered: auto|pipeline.ordered: false|' /etc/logstash/logstash.yml
sed -i 's|# queue.type: memory|queue.type: persisted|' /etc/logstash/logstash.yml
sed -i 's|# queue.max_bytes: 1024mb|queue.max_bytes: 5gb|' /etc/logstash/logstash.yml
sed -i 's|# dead_letter_queue.enable: false|dead_letter_queue.enable: true|' /etc/logstash/logstash.yml
sed -i 's|# dead_letter_queue.max_bytes: 1024mb|dead_letter_queue.max_bytes: 2gb|' /etc/logstash/logstash.yml

cat <<EOT2 >> /home/logstash/pipelines/http_8077.conf
input
{
    http
    {
        port => 8077
        codec => json
    }
}
output
{
    stdout
    {
        codec => rubydebug { metadata => true }
    }
}
EOT2

chown -R logstash:logstash /home/logstash/pipelines/*

cat <<EOT3 >> /etc/logstash/pipelines.yml
- pipeline.id: http_input_8077
  path.config: "/home/logstash/pipelines/http_8077.conf"
EOT3

sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable logstash.service
sudo /bin/systemctl start logstash.service