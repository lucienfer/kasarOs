#!/bin/bash

set -eu -o pipefail

OSIRIS_PATH=$(pwd)
CLIENT_DIR="$OSIRIS_PATH/client"
LOGS_PATH="$OSIRIS_PATH/network/logs.txt"
TRACK_MODE=false

check_track() {
    echo "$@"
    for arg in "$@"
    do
        case $arg in
            --track)
                TRACK_MODE=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
}

# Utils
# Define colors
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
purple='\033[0;35m'
cyan='\033[0;36m'
white='\033[0;37m'
reset='\033[0m'

# Clear + Banner

osirisClear() {
    clear
    echo -e "\n"
    echo -e "\e[1;33m⠐⢤⣀⣀⡀⠀⠀⠀⢀⣀⣀⣀⣀⣠⣤⣤⣤⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⠀⠀\e[0m"
    echo -e "\e[1;33m⡄⠀⠈⠛⠿⢿⡿⠟⠛⠛⠛⠛⠛⠛⠛⠉⠉⠉⠉⠉⠁⠀⠀⠈⠉⠉⠛⠻⡇⠀\e[0m"
    echo -e "\e[1;33m⢹⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣤⣴⣶⣶⣶⣶⣦⣄⠀⠀⠀⠁⠀\e[0m"
    echo -e "\e[1;33m⠀⢻⣿⣿⣶⣶⣦⣤⣤⣤⣤⣤⣶⣾⣿⣿⠿⠛⢋⣿⣿⣿⣿⡛⢿⣷⣄⠀⠀⠀\e[0m"
    echo -e "\e[1;33m⠀⠀⣿⣿⣿⡿⢿⣿⣿⣿⣿⣿⣿⣭⣁⡀⠀⠀⠸⣿⣿⣿⣿⠇⠀⣘⣿⣿⣦⡄ \t\t\033[1;33mOsiris v0.1.0-beta.1"
    echo -e "\e[1;33m⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠉⠉⠛⠿⢿⣿⣿⣶⣶⣿⣿⣿⣿⣶⣿⣿⡿⠿⠿⣇    \t\033[1;35mBy Kasar Labs"
    echo -e "\e[1;33m⠀⠀⠀⠀⠀⠀⠐⣶⣤⡀⠀⠀⠀⠀⠀⠀⠉⠙⠛⣻⣿⣿⣿⡟⠉⠀⠀⠀⠀⠀\e[0m"
    echo -e "\e[1;33m⠀⠀⠀⠀⢀⣶⡿⠿⢿⣿⡆⠀⠀⠀⠀⠀⠀⣀⣴⣿⣿⢿⣿⡅⢸⠀⠀⠀⠀⠀\e[0m"
    echo -e "\e[1;33m⠀⠀⠀⠀⣿⡏⠀⠀⠀⢹⠇⠀⠀⠀⢀⣠⣾⣿⡿⠋⠁⢸⣿⣿⡟⠀⠀⠀⠀⠀\e[0m"
    echo -e "\e[1;33m⠀⠀⠀⠀⢿⣷⡀⠀⠔⠋⢀⣀⣤⣶⣿⡿⠛⠁⠀⠀⠀⢸⣿⡟⠀⠀⠀⠀⠀⠀\e[0m"
    echo -e "\e[1;33m⠀⠀⠀⠀⠀⠙⠿⠿⣿⣿⡿⠿⠟⠋⠁⠀⠀⠀⠀⠀⠀⢸⣿⠀⠀⠀⠀⠀⠀⠀\e[0m"
    echo -e "\e[1;33m⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⠀⠀⠀⠀⠀⠀⠀\e[0m"
    echo -e "\e[1;33m⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡿⠿⠆⠀⠀⠀⠀⠀⠀\e[0m"
}

# Define options and default selected option
selected=0

# Function to print the menu
print_menu() {
    local message=$1
    local question=$2
    shift 2
    local options=("${@}")

    while true; do
        osirisClear
        echo -e "\n\n${message}"
        echo -e "${question}\n"
        for i in "${!options[@]}"; do
            if [ $i -eq $selected ]; then
                echo -e "${red}>  ${options[$i]}${reset}"
            else
                echo -e "${yellow}   ${options[$i]}${reset}"
            fi
        done

        # Loop for user input
        read -sn1 input
        case $input in
            A) # Up arrow
                selected=$((selected-1))
                if [ $selected -lt 0 ]; then
                    selected=$((${#options[@]}-1))
                fi
                ;;
            B) # Down arrow
                selected=$((selected+1))
                if [ $selected -ge ${#options[@]} ]; then
                    selected=0
                fi
                ;;
            "") # Enter key
                osirisClear
                if [ "${options[$selected]}" = "Quit" ]; then
                    echo -e "\nSee you soon!"
                    exit
                else
                    echo -e "\nYou selected ${options[$selected]}\n"
                fi
                break
                ;;
        esac
    done
}

getClient() {
	if sudo docker ps -a | grep juno > /dev/null
	then
		node_docker="juno"
	elif sudo docker ps -a | grep papyrus > /dev/null
	then
		node_docker="papyrus"
	elif sudo docker ps -a | grep pathfinder > /dev/null
	then
		node_docker="pathfinder"
    elif sudo docker ps -a | grep geth > /dev/null
	then
		node_docker="geth"
    elif sudo docker ps -a | grep taiko > /dev/null
	then
		node_docker="taiko"
    elif sudo docker ps -a | grep celo > /dev/null
	then
		node_docker="celo"
    elif sudo docker ps -a | grep gnosis > /dev/null
	then
		node_docker="gnosis"
    elif sudo docker ps -a | grep scroll > /dev/null
	then
		node_docker="scroll"
	else
		node_docker="null"
	fi
}

menu_installer() {
    reset
    osirisClear
    options=("Track" "Stop" "Restart" "Delete" "Quit")
    yesOrNo=("Yes" "No" "Quit")
    selected=0 # Initialize the selected variable
    print_menu "Welcome back to myOsiris!" "A client has been detected on this machine. Please chose your option!" "${options[@]}"

    if [ "${options[$selected]}" = "Track" ]; then
        osirisClear
        echo -e -n "\n${red}Tracking view mode will exit in 10secs${reset}\n"
        client=$(jq -r '.client' config.json)
        if sudo docker exec $client pgrep $client > /dev/null; then
            sudo docker logs -f $client &>> $LOGS_PATH & nohup ./myOsiris&
            sleep 2
        fi
        timeout 10s tail -f nohup.out
    fi
    if [ "${options[$selected]}" = "Stop" ]; then
        osirisClear
        sudo docker stop ${node_docker} > /dev/null
        echo -e "\nNode stoped.\n"
        exit
    fi
    if [ "${options[$selected]}" = "Restart" ]; then
        osirisClear
        sudo docker start ${node_docker} > /dev/null
        echo -e "\nNode started.\n"
        sudo docker logs -f papyrus &>> $LOGS_PATH & nohup ./myOsiris&
        exit
    fi
    if [ "${options[$selected]}" = "Delete" ]; then
        osirisClear
        echo -e "\nNode deleted.\n"
        refreshClient
        exit
    fi
}

menu_running() {
    osirisClear
    options=("Starknet" "Quit")
    yesOrNo=("Yes" "No" "Quit")
    selected=0 # Initialize the selected variable
    print_menu "Welcome to myOsiris!" "Please chose the chain you'd like to setup" "${options[@]}"

    if [ "${options[$selected]}" = "Starknet" ]; then
        menu_starknet
    elif [ "${options[$selected]}" = "Taiko" ]; then
        installTools
        installTaiko
    elif [ "${options[$selected]}" = "Ethereum" ]; then
        menu_ethereum
    elif [ "${options[$selected]}" = "Celo" ]; then
        installTools
        installCelo
    elif [ "${options[$selected]}" = "Scroll" ]; then
        installTools
        installScroll
    fi
}

menu_starknet() {
    osirisClear
    options=("Papyrus - Starkware" "Pathfinder - Equilibrium" "Juno - Nethermind" "Quit")
    yesOrNo=("Yes" "No" "Quit")
    selected=0 # Initialize the selected variable
    print_menu "You selected Starknet" "Please chose the client you'd like to install" "${options[@]}"
    # Prompt for node name, rpc_key, and osiris_key
    echo -e -n "${yellow}> Enter a name for your node:${reset} "
    read node_name
    echo -e -n "${yellow}> Enter your Ethereum RPC url:${reset} "
    read rpc_key
    osiris_key="null"

    # Create a JSON object and store it in config.json
    if [ "${options[$selected]}" = "Papyrus - Starkware" ]; then
        client="papyrus"
        installTools
        installPapyrus
    elif [ "${options[$selected]}" = "Juno - Nethermind" ]; then
        client="juno"
        installTools
        installJuno
    elif [ "${options[$selected]}" = "Pathfinder - Equilibrium" ]; then
        client="pathfinder"
        installTools
        installPathfinder
    fi
    echo "{\"name\": \"${node_name}\", \"client\": \"${client}\", \"rpc_key\": \"${rpc_key}\", \"osiris_key\": \"${osiris_key}\"}" > config.json    
}

menu_ethereum() {
    osirisClear
    options=("Geth - Ethereum" "Nethermind - Nethermind" "Besu - Hyperledger" "Erigon - Ledgerstack" "Quit")
    yesOrNo=("Yes" "No" "Quit")
    selected=0 # Initialize the selected variable
    print_menu "You selected Ethereum" "Please chose the execution client you'd like to install (currently using Lodestar concensus client)" "${options[@]}"
    # Prompt for node name, rpc_key, and osiris_key
    echo -e -n "${yellow}> Enter a name for your node:${reset} "
    read node_name
    echo -e -n "${yellow}> Enter your Osiris key:${reset} "
    read osiris_key

    # Create a JSON object and store it in config.json
    if [ "${options[$selected]}" = "Geth - Ethereum" ]; then
        client="geth"
        installTools
        installGeth
    elif [ "${options[$selected]}" = "Nethermind - Nethermind" ]; then
        client="nethermind"
        installTools
        installGeth
    elif [ "${options[$selected]}" = "Besu - Hyperl" ]; then
        client="besu"
        installTools
        installGeth
    elif [ "${options[$selected]}" = "Erigon - Ledgerwatch" ]; then
        client="erigon"
        installTools
        installGeth
    fi
    echo "{\"name\": \"${node_name}\", \"client\": \"${client}\", \"rpc_key\": \"${rpc_key}\", \"osiris_key\": \"${osiris_key}\"}" > config.json    
}

main(){
    check_track "$@"
    getClient
    if [ "${node_docker}" = "null" ]; then
        menu_running
    else
        menu_installer
    fi
}

installPapyrus() {
    osirisClear
    echo -e "\n\033[34mCloning and running docker... \033[m"
    sleep 1
    refreshClient
    git clone git@github.com:starkware-libs/papyrus.git $CLIENT_DIR
    sudo docker run -d --rm --name papyrus \
        -p 8080-8081:8080-8081 \
        -v $CLIENT_DIR:/app/data \
        ghcr.io/starkware-libs/papyrus:dev
    # Wait for the Papyrus client to start
    osirisClear
    echo -e "\n\033[34mWaiting for Papyrus client to start... \033[m"
    while ! sudo docker exec papyrus pgrep papyrus > /dev/null; do sleep 1; done
    echo "{\"name\": \"${node_name}\", \"client\": \"${client}\", \"rpc_key\": \"${rpc_key}\", \"osiris_key\": \"${osiris_key}\"}" > config.json    
    go build
    echo -e "\n\033[32m$(cat ./config.json | jq -r '.name') full node is running correctly using Papyrus client!\033[m"
    echo -e "\033[32mTo stop or remove it please run setup.sh again\033[m"
    if [ $TRACK_MODE == true ]; then
        sudo docker logs -f papyrus &>> $LOGS_PATH & nohup ./myOsiris&
        sleep 2
        echo -e -n "\n${red}Tracking view mode will exit in 10secs${reset}\n"
        timeout 10s tail -f nohup.out
    else
        exit
    fi
}

installJuno() {
    osirisClear
    echo -e "\n\033[34mCloning and running docker... \033[m"
    sleep 1
    refreshClient
    git clone https://github.com/NethermindEth/juno $CLIENT_DIR
    sudo docker run -d -it --name juno \
        -p 6060:6060 \
        -v $CLIENT_DIR:/var/lib/juno \
        nethermindeth/juno \
        --rpc-port 6060 \
        --db-path /var/lib/juno
    # Wait for the Juno client to start
    osirisClear
    echo -e "\n\033[34mWaiting for Juno client to start... \033[m"
   	while ! sudo docker exec juno pgrep juno > /dev/null; do sleep 1; done
    echo "{\"name\": \"${node_name}\", \"client\": \"${client}\", \"rpc_key\": \"${rpc_key}\", \"osiris_key\": \"${osiris_key}\"}" > config.json    
    go build
    echo -e "\n\033[32m$(cat ./config.json | jq -r '.name') full node is running correctly using Juno client!\033[m"
    echo -e "\033[32mTo stop or remove it please run setup.sh again\033[m"
    if [ $TRACK_MODE == true ]; then
        sudo docker logs -f juno &>> $LOGS_PATH & nohup ./myOsiris&
        sleep 2
        echo -e -n "\n${red}Tracking view mode will exit in 10secs${reset}\n"
        timeout 10s tail -f nohup.out
    else
        exit
    fi
}

installPathfinder() {
    osirisClear
    echo -e "\n\033[34mCloning and running docker... \033[m"
    sleep 1
    refreshClient
    git clone git@github.com:eqlabs/pathfinder.git $CLIENT_DIR
    sudo mkdir -p $HOME/pathfinder
    sudo chmod 777 $HOME/pathfinder
    sudo docker run \
        --name pathfinder \
        --restart unless-stopped \
        --detach \
        -p 9545:9545 \
        --user "$(id -u):$(id -g)" \
        -e RUST_LOG=info \
        -e PATHFINDER_ETHEREUM_API_URL="$(cat ./config.json | jq -r '.rpc_key')" \
        -v $CLIENT_DIR:/usr/share/pathfinder/data \
        eqlabs/pathfinder > /dev/null
    # Wait for the Pathfinder client to start
    osirisClear
    echo -e "\n\033[34mWaiting for Pathfinder client to start... \033[m"
   	while ! sudo docker logs pathfinder > /dev/null; do sleep 1; done
    echo "{\"name\": \"${node_name}\", \"client\": \"${client}\", \"rpc_key\": \"${rpc_key}\", \"osiris_key\": \"${osiris_key}\"}" > config.json    
    go build
    echo -e "\n\033[32mPathfinder full node is running correctly using Pathfinder client!\033[m"
    if [ $TRACK_MODE == true ]; then
        sudo docker logs -f pathfinder &>> $LOGS_PATH & nohup ./myOsiris&
        sleep 2
        echo -e -n "\n${red}Tracking view mode will exit in 10secs${reset}\n"
        timeout 10s tail -f nohup.out
    else
        exit
    fi
}

installGeth() {
    osirisClear
    echo -e "\n\033[34mCloning and running docker... \033[m"
    sleep 1
    refreshClient
    git clone https://github.com/ChainSafe/lodestar-quickstart $CLIENT_DIR
    cd $CLIENT_DIR
    sed -i 's|LODESTAR_EXTRA_ARGS="--network mainnet $LODESTAR_FIXED_VARS"|LODESTAR_EXTRA_ARGS="--checkpointSyncUrl https://beaconstate-mainnet.chainsafe.io --network mainnet $LODESTAR_FIXED_VARS"|g' ./mainnet.vars
    ./setup.sh --dataDir goerli-data --elClient geth --network mainnet --detached --dockerWithSudo
    # Wait for the Geth client to start
    osirisClear
    echo -e "\n\033[34mWaiting for Geth container to be in a running state... \033[m"
    while [[ "$(sudo docker inspect -f '{{.State.Status}}' mainnet-geth)" != "running" ]]; do sleep 1; done
    osirisClear
    echo -e "\n\033[34mWaiting for Geth client to start... \033[m"
    sudo docker logs mainnet-geth
    while ! sudo docker exec mainnet-geth grep Ethereum > /dev/null; do sleep 1; done
    echo "{\"name\": \"${node_name}\", \"client\": \"${client}\", \"rpc_key\": \"${rpc_key}\", \"osiris_key\": \"${osiris_key}\"}" > config.json
    go build
    echo -e "\n\033[32m$name full node is running correctly using Geth client!\033[m"
    if [ $TRACK_MODE == true ]; then
        sudo docker logs -f geth &>> $LOGS_PATH & nohup ./myOsiris&
        sleep 2
        echo -e -n "\n${red}Tracking view mode will exit in 10secs${reset}\n"
        timeout 10s tail -f nohup.out
    else
        exit
    fi
}

installTaiko() {
    osirisClear
    echo -e "\n\033[34mCloning Taiko node... \033[m"
    sleep 1
    refreshClient
    git clone https://github.com/taikoxyz/simple-taiko-node.git $CLIENT_DIR
    cd $CLIENT_DIR
    osirisClear
    echo -e "\n\033[34mConfiguring Taiko node... \033[m"
    sleep 1
    cp .env.sample .env
    sed -i 's/L1_ENDPOINT_HTTP=.*/L1_ENDPOINT_HTTP=https:\/\/l1rpc.a2.taiko.xyz/g' .env
    sed -i 's/L1_ENDPOINT_WS=.*/L1_ENDPOINT_WS=wss:\/\/l1ws.a2.taiko.xyz/g' .env
    sed -i 's/\(- --ws.origins.*\)/\0\n  - --p2p.syncTimeout\n  - "600"/' docker-compose.yml
    osirisClear
    echo -e "\n\033[34mStarting Taiko node... \033[m"
    sleep 1
    sudo docker compose up -d
    echo -e "\n\033[34mExposing RPC endpoint...\033[m"
    sudo ufw enable
    sudo ufw allow 8545
    PUBLIC_IP=$(curl -s ifconfig.me)
    echo -e "\n\033[32mCelo full node RPC is exposed correctly at: http://$PUBLIC_IP:8545\033[m"
}

installCelo() {
    osirisClear
    echo -e "\n\033[34mSetting up Celo full node... \033[m"
    sleep 1
    refreshClient

    # Set up the environment variable
    export CELO_IMAGE=us.gcr.io/celo-org/geth:mainnet

    # Pull the Celo Docker image
    sudo docker pull $CELO_IMAGE

    # Set up the data directory
    mkdir -p $HOME/client
    CELO_DATA_DIR=$HOME/client/celo-data-dir
    mkdir -p $CELO_DATA_DIR
    chmod 777 $CELO_DATA_DIR

    # Create an account and get its address
    sudo docker run -v $CELO_DATA_DIR:/root/.celo --rm -it $CELO_IMAGE account new
    echo "Please copy and paste your Celo public key and press Enter:"
    read CELO_ACCOUNT_ADDRESS

    echo "Celo account address: $CELO_ACCOUNT_ADDRESS"
    # Start the Celo full node
    sudo docker run --name celo -d --restart unless-stopped --stop-timeout 300 -p 127.0.0.1:8545:8545 -p 127.0.0.1:8546:8546 -p 30303:30303 -p 30303:30303/udp -v $PWD:/root/.celo $CELO_IMAGE --verbosity 3 --syncmode full --http --http.addr 0.0.0.0 --http.api eth,net,web3,debug,admin,personal --light.serve 90 --light.maxpeers 1000 --maxpeers 1100 --etherbase $CELO_ACCOUNT_ADDRESS --datadir /root/.celo

    osirisClear
    echo -e "\n\033[34mWaiting for Celo full node to start... \033[m"
   	while ! sudo docker logs celo > /dev/null; do sleep 1; done
    echo -e "\n\033[32mCelo full node is running correctly!\033[m"
    echo -e "\n\033[34mExposing RPC endpoint...\033[m"
    sudo ufw enable
    sudo ufw allow 8545
    PUBLIC_IP=$(curl -s ifconfig.me)
    echo -e "\n\033[32mCelo full node RPC is exposed correctly at: http://$PUBLIC_IP:8545\033[m"

    if [ $TRACK_MODE == true ]; then
        sudo docker logs -f celo &>> $LOGS_PATH & nohup ./myOsiris &
        sleep 2
        echo -e -n "\n${red}Tracking view mode will exit in 10secs${reset}\n"
        timeout 10s tail -f nohup.out
    else
        exit
    fi
}

installScroll() {
  # Step 1: Download genesis.json
  echo "Downloading genesis.json..."
  curl -o ./genesis.json https://www.notion.so/genesis-json-c65ec90622a14e9bb22d82750c1a621e

  # Step 3 and 4: Create a directory for persistent data
  echo "Creating /l2geth-datadir for persistent data storage..."
  sudo mkdir -p /l2geth-datadir

  # Step 5: Run a container using the created image
  echo "Running l2geth-docker container..."
  docker run -d --name l2geth-docker \
    -p 8545:8545 -p 8546:8546 -p 8547:8547 -p 30303:30303 -p 30303:30303/udp \
    -v $(pwd)/l2geth-datadir:/l2geth-datadir \
    scroll_l2geth

  echo "l2geth-docker container is now running."
  # Step 7: In a separate shell, you can now attach to l2geth
  echo "In a separate shell, you can now attach to l2geth using the following command:"
  echo "docker exec -it l2geth-docker geth attach"
}

installTools() {
    osirisClear
    echo -e "\n\033[34mInstalling tools pre-requisites... \033[m\n"
    sleep 1
    while read -r p ; do sudo apt install -y $p ; done < <(cat << "EOF"
        build-essential
        libncurses5-dev
        libpcap-dev
        git
        jq
        ufw
EOF
)
    osirisClear
    echo -e "\n\033[34mInstalling tools... \033[m\n"
    if ! command -v docker &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y \
            apt-transport-https \
            ca-certificates \
            curl \
            gnupg \
            lsb-release
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=arm64] download.docker.com/linux/ubuntu focal stable" | sudo tee /etc/apt/sources.list.d/docker.list
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    fi
    if ! command go version >/dev/null; then
        echo "Installing go language package version 1.20.2"
        sudo tar -C /usr/local -xzf ~/go1.20.4.linux-arm64.tar.gz
        echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a /etc/environment > /dev/null
        sudo chmod 0644 /etc/environment
        source /etc/environment
    fi
    while read -r p ; do sudo apt install -y $p ; done < <(cat << "EOF"
        sysstat
        bc
EOF
)

    if [ ! -d "$(pwd)/tmp/" ]
    then
        mkdir $(pwd)/tmp/
    fi

    # git -C $(pwd)/tmp/ clone https://github.com/raboof/nethogs > $(pwd)/tmp/sample.log 2>&1
    # sudo make install -C $(pwd)/tmp/nethogs/ >> $(pwd)/tmp/sample.log 2>&1
    # rm -rf $(pwd)/tmp/
}

refreshClient()
{
	if sudo docker ps -a | grep juno > /dev/null 
	then
		sudo docker rm -f juno > /dev/null
		sudo docker image rm -f nethermindeth/juno > /dev/null
        rm -rf ./nohup.out > /dev/null
		rm -f $LOGS_PATH > /dev/null
	fi
	if sudo docker ps -a | grep papyrus > /dev/null
	then
		sudo docker rm -f papyrus > /dev/null
		sudo docker image rm -f ghcr.io/starkware-libs/papyrus:dev > /dev/null
        rm -rf ./nohup.out > /dev/null
		rm -f $LOGS_PATH > /dev/null
	fi
	if sudo docker ps -a | grep pathfinder > /dev/null
	then
		sudo docker rm -f pathfinder > /dev/null
		# sudo docker image rm -f eqlabs/pathfinder > /dev/null
        rm -rf ./nohup.out > /dev/null
		rm -f $LOGS_PATH > /dev/null
	fi
    if sudo docker ps -a | grep mainnet-geth > /dev/null
	then
		sudo docker rm -f mainnet-geth > /dev/null
		sudo docker rm -f mainnet-lodestar > /dev/null
		# sudo docker image rm -f chainsafe/lodestar > /dev/null
		# sudo docker image rm -f ethereum/client-go > /dev/null
        rm -rf ./nohup.out > /dev/null
		rm -f $LOGS_PATH > /dev/null
	fi
    if sudo docker ps -a | grep taiko > /dev/null
	then
		sudo docker rm -f taiko-client > /dev/null
		sudo docker rm -f client-grafana-1 > /dev/null
		sudo docker rm -f client-prometheus-1 > /dev/null
		sudo docker rm -f client-taiko_client_prover_relayer-1 > /dev/null
		sudo docker rm -f client-taiko_client_driver-1 > /dev/null
		sudo docker rm -f client-l2_execution_engine-1 > /dev/null
		# sudo docker image rm -f ethereum/client-go > /dev/null
        rm -rf ./nohup.out > /dev/null
		rm -f $LOGS_PATH > /dev/null
	fi
    if sudo docker ps -a | grep celo > /dev/null
	then
		sudo docker rm -f celo > /dev/null
		# sudo docker image rm -f us.gcr.io/celo-org/geth:mainnet > /dev/null
        rm -rf ./nohup.out > /dev/null
		rm -f $LOGS_PATH > /dev/null
	fi
	if [ -d $CLIENT_DIR ]
	then
		sudo rm -rf $CLIENT_DIR
	fi
}
main "$@"