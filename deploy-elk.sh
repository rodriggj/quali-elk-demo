#!/usr/bin/env bash
#SET_ENVIRONMENT_VARIABLES

# Stop Script on Error
set -e

# For Debugging (print env. variables into a file)  
printenv > /var/log/torque-vars-"$(basename "$BASH_SOURCE" .sh)".txt

# Update packages and Upgrade system
echo "****************************************************************"
echo "Updating System"
echo "****************************************************************"
sudo yum update -y

# Install Java
echo "****************************************************************"
echo "Installing Java"
echo "****************************************************************"
sudo yum -y install java-openjdk-devel java-openjdk
java -version

# Install Add ELK repository to Amazon Linux2
echo "****************************************************************"
echo "Add ELK Repository"
echo "****************************************************************"
sudo su
echo -e "[elasticsearch-8.x]\nname=Elasticsearch repository for 8.x packages\nbaseurl=https://artifacts.elastic.co/packages/8.x/yum\ngpgcheck=1\ngpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch\nenabled=1\nautorefresh=1\ntype=rpm-md" >> /etc/yum.repos.d/elasticsearch.repo
exit

# Import the GPG-Key
echo "****************************************************************"
echo "Import GPG Key"
echo "****************************************************************"
sudo rpm -import https://artifacts.elastic.co/GPG-KEY-elasticsearch

# Clear the cache
echo "****************************************************************"
echo "Clearing Cache"
echo "****************************************************************"
sudo yum clean all
sudo yum makecache

# Install Elasticsearch on Amazon Linux2
echo "****************************************************************"
echo "Installing Elasticsearch"
echo "****************************************************************"
sudo yum -y install elasticsearch

# Start Elasticsearch services
echo "****************************************************************"
echo "Start Elasticsearch services"
echo "****************************************************************"
sudo systemctl start elasticsearch.service
sudo systemctl enable elasticsearch.service
sudo systemctl status elasticsearch.service
rpm -qi elasticsearch

# Configure Elasticsearch
echo "****************************************************************"
echo "Configure Elasticsearch"
echo "****************************************************************"
sudo chmod -R 755 /etc/elasticsearch/
sudo sed -i 's/#network.host: 192.168.0.1/network.host: 0.0.0.0/g' /etc/elasticsearch/elasticsearch.yml
sudo sed -i 's/#discovery.seed_hosts: \["host1", "host2"]/discovery.seed_hosts: \[]/g' /etc/elasticsearch/elasticsearch.yml
sudo sed -i 's/xpack.security.enabled: true/xpack.security.enabled: false/g' /etc/elasticsearch/elasticsearch.yml
sudo systemctl restart elasticsearch.service
sudo systemctl status elasticsearch.service

# Test Elasticsearch
echo "****************************************************************"
echo "Test Elasticsearch"
echo "****************************************************************"
curl -X GET "localhost:9200"

# Install Logstash
echo "****************************************************************"
echo "Installing Logstash"
echo "****************************************************************"
sudo yum -y install logstash
sudo systemctl enable --now logstash
sudo systemctl start logstash
sudo systemctl status logstash

# Install Kibana
echo "****************************************************************"
echo "Installing Kibana"
echo "****************************************************************"
sudo yum -y install kibana
sudo systemctl start kibana
sudo systemctl enable kibana
sudo systemctl status kibana

# Configure Kibana  
echo "****************************************************************"
echo "Configuring Kibana"
echo "****************************************************************"
sudo chmod -R 755 /etc/kibana/
sudo sed -i 's/#server.port: 5601/server.port: 5601/g' /etc/kibana/kibana.yml
sudo sed -i 's/#server.host: "localhost"/server.host: \"0.0.0.0\"/g' /etc/kibana/kibana.yml
sudo sed -i 's/#elasticsearch.hosts:/elasticsearch.hosts:/g' /etc/kibana/kibana.yml
sudo systemctl restart kibana.service
sudo systemctl status kibana.service

# Test Kibana  
echo "****************************************************************"
echo "Test Kibana"
echo "****************************************************************"
echo "In your browser nav to http://publicIP:5601, validate that you see the Kibana dashboard."
echo "Use the Search bar to query for \'console\' which will return \'DevTools > Console\' with JSON editor"
echo "Modify editor to GET / which will return the a Kibana payload with config status"


# Install Filebeat  
echo "****************************************************************"
echo "Install Filebeat"
echo "****************************************************************"
sudo yum -y install filebeat
sudo systemctl start filebeat
sudo systemctl enable filebeat
sudo systemctl status filebeat

# Configure Filebeat  
echo "****************************************************************"
echo "Configuring Filebeat"
echo "****************************************************************"
sudo chmod -R 755 /etc/filebeat/
sudo sed -i 's/output.elasticsearch:/#output.elasticsearch:/g' /etc/filebeat/filebeat.yml
sudo sed -i 's/  hosts: \["localhost:9200"]/#  hosts: \["localhost:9200"]/g' /etc/filebeat/filebeat.yml
sudo sed -i 's/#output.logstash:/output.logstash:/g' /etc/filebeat/filebeat.yml
sudo sed -i 's/  #hosts: \["localhost:5044"]/  hosts: \["localhost:5044"]/g' /etc/filebeat/filebeat.yml
sudo systemctl restart filebeat.service
sudo systemctl status filebeat.service

# Configure Filebeat  
echo "****************************************************************"
echo "Configuring Filebeat Index "
echo "****************************************************************"
# Need to make the IP for this dynamic, HostIP is currently hardcoded.
sudo filebeat setup --index-management -E output.logstash.enabled=false -E 'output.elasticsearch.hosts=["44.234.119.58:9200"]'
sudo systemctl restart filebeat.service
sudo systemctl status filebeat.service

# Test Filebeat  
echo "****************************************************************"
echo "Testign Filebeat Service"
echo "****************************************************************"
# Need to make the IP for this dynamic, HostIP is currently hardcoded.
curl -XGET http://44.234.119.58:9200/_cat/indices?v