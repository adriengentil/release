#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

echo "************ baremetalds assisted baremetal conf user-data command ************"

tee "${SHARED_DIR}/${USER_DATA_FILENAME}" << EOF
#cloud-config

packages_upgrade: true
runcmd:
  - |
    set -o nounset
    set -o errexit
    set -o pipefail

    # workaround a bug with equinix metal that does not populate the authorized hosts
    echo "$(cat ${CLUSTER_PROFILE_DIR}/packet-public-ssh-key)" >> /root/.ssh/authorized_keys

    if [ "${PACKET_PLAN}" = "c3.medium.x86" ] || [ "${PACKET_PLAN}" = "m3.small.x86" ]
    then
      # c3.medium.x86 and m3.small.x86 have 64GB of RAM which is not enough for most of assisted jobs.
      # We need to mount extra swap space in order allow memory overcommit with libvirt/KVM.
      #
      # c3.medium.x86 is supposed to have 2x240G disks (one is used for the system) and
      # 2x480GB disks (sometimes missing).
      #
      # m3.small.x86 has 2 x 480GB disks (one is used for the system)

      # Get disk where '/' is mounted
      ROOT_DISK=\$(lsblk -o pkname --noheadings --path | grep -E "^\S+" | sort | uniq)

      # Setup the smallest disk available as swap
      SWAP_DISK=\$(lsblk -o name --noheadings --sort size --path | grep -v "\${ROOT_DISK}" | head -n1)
      mkswap "\${SWAP_DISK}"
      swapon "\${SWAP_DISK}"
    fi
EOF
