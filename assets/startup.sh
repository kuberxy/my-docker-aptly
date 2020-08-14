#! /bin/bash

# If the repository GPG keypair doesn't exist, create it.
if [[  -f /opt/gpg_batch.sh ]]; then
  /opt/gpg_batch.sh
  # If your system doesn't have a lot of entropy this may, take a long time
  # Google how-to create "artificial" entropy if this gets stuck
  gpg --batch --gen-key /opt/gpg_batch
fi

# Export the GPG Public key
if [[ ! -f /var/lib/aptly/public/aptly_repo_signing.key ]]; then
  mkdir -p /var/lib/aptly/public/
  gpg --armor --output /var/lib/aptly/public/aptly_repo_signing.key --export ${FULL_NAME}
fi

# Import Ubuntu keyrings if they exist
if [[ -f /usr/share/keyrings/ubuntu-archive-keyring.gpg ]]; then
  gpg --list-keys
  gpg --no-default-keyring                                     \
      --keyring /usr/share/keyrings/ubuntu-archive-keyring.gpg \
      --export |                                               \
  gpg --no-default-keyring                                     \
      --keyring trustedkeys.gpg                                \
      --import
fi

# Generate Nginx Config
/opt/nginx.conf.sh

# Start Supervisor
/usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
