#! /bin/bash

set -e
UBUNTU_RELEASE=bionic
KEY_URL="https://openresty.org/package/pubkey.gpg"
UPSTREAM_URL=(
"https://mirrors.tuna.tsinghua.edu.cn/openresty/ubuntu/"
)
REPOS=(bionic)
COMPONENTS=(main)
PKGS=(openresty)
VERS=("(= 1.15.8.3-1~bionic1)")
set +e

# Create local repository if they don't exist
aptly repo list -raw | grep "^local$" &> /dev/null
if [[ $? -ne 0 ]]; then
    set -e
    echo -n "Creating local repository..."
    aptly  -distribution ${UBUNTU_RELEASE} -component main \
      repo create local
    echo
    set +e
fi

# Import repository key
set -e
wget -O - ${KEY_URL} | gpg --no-default-keyring --keyring trustedkeys.gpg --import
set +e

for i in $(seq ${#COMPONENTS[*]}); do
  i=$((i-1))

  # Create repository mirrors
  aptly mirror list -raw | grep "^${UBUNTU_RELEASE}-${COMPONENTS[$i]}$" &> /dev/null
  if [[ $? -ne 0 ]]; then
    set -e
    aptly mirror create -architectures=amd64 \
      -force-components -filter="${PKGS[$i]} ${VERS[$i]}" -filter-with-deps \
      ${UBUNTU_RELEASE}-${COMPONENTS[$i]} ${UPSTREAM_URL[$i]} ${REPOS[*]} ${COMPONENTS[$i]}
    set +e
  fi

  # Update repository mirrors
  set -e
  aptly mirror update ${UBUNTU_RELEASE}-${COMPONENTS[$i]}
  set +e

  # Import mirror to local repository
  set -e
  aptly repo import -architectures=amd64 -with-deps \
    ${UBUNTU_RELEASE}-${COMPONENTS[$i]} local ${PKGS[$i]}
  set +e
done

# Publish/Update  local repository
aptly  publish list | grep ".*${UBUNTU_RELEASE}.* publishes .*local.*"
if [[ $? -ne 0 ]]; then
    set -e
    echo "Publish local repository..."
    aptly -passphrase="${GPG_PASSWORD}" publish repo local
    set +e
else
    set -e
    echo "Update local repository..."
    aptly -passphrase="${GPG_PASSWORD}" publish update ${UBUNTU_RELEASE}
    set +e
fi
