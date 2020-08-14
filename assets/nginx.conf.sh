#! /bin/bash

cat << EOF > /etc/nginx/sites-available/default
server_names_hash_bucket_size 64;
server {
  root /var/lib/aptly/public;
  server_name ${HOSTNAME};

  location / {
    autoindex on;
  }
}
EOF
