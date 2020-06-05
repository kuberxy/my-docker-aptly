#! /bin/bash
set -e

UBUNTU_RELEASE=bionic
KEY_URL="https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc"
UPSTREAM_URL=(
"https://dl.bintray.com/rabbitmq-erlang/debian"
"https://dl.bintray.com/rabbitmq/debian"
)
REPOS=(bionic)
COMPONENTS=(erlang-21.x rabbitmq-server-v3.7.x)
PKGS=(erlang rabbitmq-server)
VERS=("(>= 21.3.8.0)" "(>= 3.7.0)")

# Create local repository if they don't exist
set +e
aptly repo list -raw | grep "^local$" &> /dev/null
if [[ $? -ne 0 ]]; then
    echo -n "Creating local repository..."
    aptly  -distribution ${UBUNTU_RELEASE} -component main \
      repo create local
    echo
fi
set -e

# Import repository key
set +e
wget -O - ${KEY_URL} | gpg --no-default-keyring --keyring trustedkeys.gpg --import
set -e

for i in $(seq ${#COMPONENTS[*]}); do
  i=$((i-1))

  # Create repository mirrors
  set +e
  aptly mirror list -raw | grep "^${UBUNTU_RELEASE}-${COMPONENTS[$i]}$" &> /dev/null
  if [[ $? -ne 0 ]]; then
    aptly mirror create -architectures=amd64 \
      -force-components -filter="${PKGS[$i]} ${VERS[$i]}" -filter-with-deps \
      ${UBUNTU_RELEASE}-${COMPONENTS[$i]} ${UPSTREAM_URL[$i]} ${REPOS[*]} ${COMPONENTS[$i]}
  fi
  set -e

  # Update repository mirrors
  set +e
  aptly mirror update ${UBUNTU_RELEASE}-${COMPONENTS[$i]}
  set -e

  # Import mirror to local repository
  set +e
  aptly repo import -architectures=amd64 -with-deps \
    ${UBUNTU_RELEASE}-${COMPONENTS[$i]} local ${PKGS[$i]}
  set -e
done

# Publish/Update  local repository
set +e
aptly  publish list | grep ".*${UBUNTU_RELEASE}.* publishes .*local.*"
if [[ $? -ne 0 ]]; then
    echo "Publish local repository..."
    aptly -passphrase="${GPG_PASSWORD}" publish repo local 
else
    echo "Update local repository..."
    aptly -passphrase="${GPG_PASSWORD}" publish update ${UBUNTU_RELEASE}
fi
set -e
