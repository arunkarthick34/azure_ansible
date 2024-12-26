#!/bin/bash
set -e

for arg in "$@"; do
  if [ "$arg" == "--help" ] || [ "$arg" == "-h" ]; then
    echo "Cudo Miner installation options"
    echo "  --install-mode=<headless|desktop>"
    echo "  --install-cli"
    echo "  --update-channel=<stable|experimental|disabled>"
    echo "  --quiet"
    exit
  fi
  if [ "$arg" == "--update-channel=stable" ]; then
    UPDATE_CHANNEL="1"
  elif [ "$arg" == "--update-channel=experimental" ]; then
    UPDATE_CHANNEL="2"
  elif [ "$arg" == "--update-channel=disabled" ]; then
    UPDATE_CHANNEL="3"
  fi
  if [ "$arg" == "--install-mode=desktop" ]; then
    INSTALL_TYPE="1"
  elif [ "$arg" == "--install-mode=headless" ]; then
    INSTALL_TYPE="2"
  fi
  if [ "$arg" == "--install-cli" ]; then
    CMD_TOOLS="y"
  fi
  if [ "$arg" == "--quiet" ]; then
    QUIET="y"
  fi
done

if [ "$QUIET" != "y" ] && [ "$(dpkg -l | awk '/ cudo-miner / {print }'|wc -l)" -ge 1 ]; then
  echo "Previous version of Cudo Miner was found, do you wish to uninstall? (y/n)?"
  read UNINSTALL
  echo ""

  if [ "$UNINSTALL" != 'y' ] && [ "$UNINSTALL" != 'n' ]; then
    echo "Please enter y or n to uninstall previous versions of Cudo Miner"
    exit
  fi
fi

if [ -z "$INSTALL_TYPE" ]; then
  echo "Please select one of the following installation types:"
  echo "  1) Desktop app"
  echo "     Perfect for beginners, graphical user interface."
  echo "  2) Headless"
  echo "     Worker service only which can be started and stopped using systemd."

  #read INSTALL_TYPE
  INSTALL_TYPE="2"
  echo ""
fi

if [ "$INSTALL_TYPE" != '1' ] && [ "$INSTALL_TYPE" != '2' ]; then
  echo "Please enter option 1 or 2 from the installation options"
  exit
fi

if [ "$INSTALL_TYPE" == '2' ]; then
  if [ "$QUIET" != "y" ]; then
    echo "Please enter an organization username to login:"
    #read ORG
    ORG="harsh-alligator-2"
    #ORG="shrill-chickadee-7"
    echo ""
  fi

  if [ "$QUIET" != "y" ]; then
    if [ -z "$CMD_TOOLS" ]; then
      echo "Install command line tools for worker service control (y/n)?"
      #read CMD_TOOLS
      CMD_TOOLS="y"
      echo ""
    fi

    if [ "$CMD_TOOLS" != 'y' ] && [ "$CMD_TOOLS" != 'n' ]; then
      echo "Please enter y or n to install command line tools"
      exit
    fi
  fi
fi

if [ -z "$UPDATE_CHANNEL" ]; then
  echo "Please select one of the following update channels to use:"
  echo "  1) Stable Channel"
  echo "     Recommended for most users, fully tested and stable."
  echo "  2) Experimental Channel"
  echo "     Bleeding edge builds, latest features and can be unstable."
  echo "  3) No Auto Updates"
  echo "     Advanced users only, manual installation using a Debian package."
  #read UPDATE_CHANNEL
  UPDATE_CHANNEL="2"
  echo ""
fi

if [ "$UPDATE_CHANNEL" != '1' ] && [ "$UPDATE_CHANNEL" != '2' ] && [ "$UPDATE_CHANNEL" != '3' ]; then
  echo "Please enter option 1, 2 or 3 from update channels"
  exit
fi

if [ "$UNINSTALL" == "y" ]; then
  echo "Unintalling previous version of Cudo Miner..."
  sudo apt-get autoremove --purge cudo-miner
fi

if [ "$UPDATE_CHANNEL" == "1" ]; then
  echo "Installing the stable Cudo Miner APT repository..."
  echo -n 'deb [arch=amd64] https://download.cudo.org/repo/apt/ stable main' > /etc/apt/sources.list.d/cudo.list
elif [ "$UPDATE_CHANNEL" == "2" ]; then
  echo "Installing the experimental Cudo Miner APT repository..."
  echo -n 'deb [arch=amd64] https://download.cudo.org/repo/apt/ experimental main' > /etc/apt/sources.list.d/cudo.list
elif [ "$UPDATE_CHANNEL" == "3" ]; then
  echo "Downloading the Debian packages to a temporary location..."

  HEADLESS_TEMP=$(mktemp)
  DESKTOP_TEMP=$(mktemp)
  CORE_TEMP=$(mktemp)
  CLI_TEMP=$(mktemp)
  SERVICE_TEMP=$(mktemp)

  if [ "$INSTALL_TYPE" == "1" ]; then
    echo "Installing the desktop packages..."

    wget -O ${DESKTOP_TEMP} https://download.cudo.org/tenants/135790374f46b0107c516a5f5e13069b/5e5f800fdf87209fdf8f9b61441e53a1/linux/x64/release/v1.6.5/cudo-miner-desktop.deb
    wget -O ${CORE_TEMP} https://download.cudo.org/tenants/135790374f46b0107c516a5f5e13069b/5e5f800fdf87209fdf8f9b61441e53a1/linux/x64/release/v1.6.5/cudo-miner-core.deb
    wget -O ${SERVICE_TEMP} https://download.cudo.org/tenants/135790374f46b0107c516a5f5e13069b/5e5f800fdf87209fdf8f9b61441e53a1/linux/x64/release/v1.6.5/cudo-miner-service.deb

    dpkg -i ${DESKTOP_TEMP} ${CORE_TEMP} ${SERVICE_TEMP}
    rm ${DESKTOP_TEMP} ${CORE_TEMP} ${SERVICE_TEMP}

  elif [ "$INSTALL_TYPE" == "2" ]; then
    if [ "$CMD_TOOLS" == "y" ]; then
      echo "Installing the headless packages..."

      wget -O ${HEADLESS_TEMP} https://download.cudo.org/tenants/135790374f46b0107c516a5f5e13069b/5e5f800fdf87209fdf8f9b61441e53a1/linux/x64/release/v1.6.5/cudo-miner-headless.deb
      wget -O ${CORE_TEMP} https://download.cudo.org/tenants/135790374f46b0107c516a5f5e13069b/5e5f800fdf87209fdf8f9b61441e53a1/linux/x64/release/v1.6.5/cudo-miner-core.deb
      wget -O ${CLI_TEMP} https://download.cudo.org/tenants/135790374f46b0107c516a5f5e13069b/5e5f800fdf87209fdf8f9b61441e53a1/linux/x64/release/v1.6.5/cudo-miner-cli.deb
      wget -O ${SERVICE_TEMP} https://download.cudo.org/tenants/135790374f46b0107c516a5f5e13069b/5e5f800fdf87209fdf8f9b61441e53a1/linux/x64/release/v1.6.5/cudo-miner-service.deb

      dpkg -i ${HEADLESS_TEMP} ${CORE_TEMP} ${CLI_TEMP} ${SERVICE_TEMP}
      rm ${HEADLESS_TEMP} ${CORE_TEMP} ${CLI_TEMP} ${SERVICE_TEMP}
    elif [ "$CMD_TOOLS" == "n" ]; then
      echo "Installing the headless packages without command line tools..."

      wget -O ${CORE_TEMP} https://download.cudo.org/tenants/135790374f46b0107c516a5f5e13069b/5e5f800fdf87209fdf8f9b61441e53a1/linux/x64/release/v1.6.5/cudo-miner-core.deb
      wget -O ${SERVICE_TEMP} https://download.cudo.org/tenants/135790374f46b0107c516a5f5e13069b/5e5f800fdf87209fdf8f9b61441e53a1/linux/x64/release/v1.6.5/cudo-miner-service.deb

      dpkg -i ${CORE_TEMP} ${SERVICE_TEMP}
      rm ${CORE_TEMP} ${SERVICE_TEMP}
    fi
  fi
fi

if [ "$UPDATE_CHANNEL" == "1" ] || [ "$UPDATE_CHANNEL" == "2" ]; then
  wget -O - https://download.cudo.org/keys/pgp/apt.asc > /etc/apt/trusted.gpg.d/cudo.asc
  apt-get -y update

  if [ "$INSTALL_TYPE" == "1" ]; then
    echo "Installing the desktop packages..."
    apt-get -y install cudo-miner-desktop --allow-unauthenticated
  elif [ "$INSTALL_TYPE" == "2" ]; then
    if [ "$CMD_TOOLS" == "y" ]; then
      echo "Installing the headless packages..."
      apt-get -y install cudo-miner-headless --allow-unauthenticated
    elif [ "$CMD_TOOLS" == "n" ]; then
      echo "Installing the headless packages without command line tools..."
      apt-get -y install cudo-miner-core cudo-miner-service --allow-unauthenticated
    fi
  fi
fi

if [ "$ORG" != "" ]; then
  echo "org=$ORG" > /etc/cudo_minerrc
fi

echo -e "\n\n"

if [ "$INSTALL_TYPE" == "1" ]; then
  echo "Installation complete, you can now find Cudo Miner in your applications"
elif [ "$INSTALL_TYPE" == "2" ]; then
  if [ "$CMD_TOOLS" == "y" ]; then
    echo "Installation complete, you may now use the cudominercli command"
  elif [ "$CMD_TOOLS" == "n" ]; then
    echo "Installation complete, you can now administrate this device from the web console"
  fi
fi

