#!/usr/bin/env bash
##########################################
## this script allow me to install
## and run some console games
##########################################

GAMES_LIST=(
    "nudoku" "Sudoku_for_CLI"
    "pacman4console" "Pacman_clone_for_console"
    "moon-buggy" "Tap_to_jump_game"
    "ninvaders" "Galaga_/_Invaders_clone"
    "zangband" "Text_RPG"
    "nethack-console" "Text_RPG"
    "nsnake" "Snake"
    "greed" "_"
    "2048-cli" "Console_2048"
)

check_installer() {
    if [[ -e /usr/bin/apt ]]; then
        UPDATEREPO='apt update'
        INSTALLER='apt install -y'
    elif [[ -e /usr/bin/apt-get ]]; then
        UPDATEREPO='apt-get update'
        INSTALLER='apt-get install -y'
    elif [[ -e /usr/bin/dnf ]]; then
        UPDATEREPO='dnf check-update'
        INSTALLER='dnf install -y'
    elif [[ -e /usr/bin/yum ]]; then
        UPDATEREPO='yum check-update'
        INSTALLER='yum install -y'
    else
        echo "Unknown installer."
        exit 1
    fi
}

list_installed_games() {
    for ((i = 0; i < ${#GAMES_LIST[@]}; i += 2)); do
        if [[ -e /usr/games/${GAMES_LIST[i]} ]]; then
            echo "${GAMES_LIST[i]} ${GAMES_LIST[i+1]}"
        fi
done
}

list_available_games() {
    for ((i = 0; i < ${#GAMES_LIST[@]}; i += 2)); do
        if [[ !(-e /usr/games/${GAMES_LIST[i]}) ]]; then
            # echo "\"${GAMES_LIST[i]}\" \"${GAMES_LIST[i+1]}\" OFF "
            echo "${GAMES_LIST[i]} ${GAMES_LIST[i+1]} OFF "
        fi
done
}
install_menu(){
    check_installer
    eval `resize`
    install_list=$(whiptail --title "Install menu" --checklist \
    "Choose gamse to install" $(( $LINES - 4 )) $(( $COLUMNS -20 )) $(( $LINES - 12 )) \
    $(list_available_games) 3>&1 1>&2 2>&3)
    if [[ $(echo $install_list | wc -w) > 0 ]]; then
        $(echo $install_list |sed 's/"//g')
        sudo $UPDATEREPO
        sudo $INSTALLER $(echo $install_list |sed 's/"//g')
    fi 
}

## check for whiptail installation
if [[ !(-e /usr/bin/whiptail) ]]; then
    echo "\"whiptail\" not found. Installing \"whiptail\"."
    check_installer
    sudo $UPDATEREPO
    sudo $INSTALLER whiptail
fi

while true; do
    eval `resize`
    CHOOSE=$(
        whiptail --title "Games menu" --menu "Choose game to run:" $(( $LINES - 4 )) $(( $COLUMNS -20 )) $(( $LINES - 12 )) \
        $(list_installed_games) \
        "Install" "Install more games" 3>&1 1>&2 2>&3
    )
    
    ## choose processing
    if [[ $(echo $CHOOSE | wc -w) -eq 0 ]]; then
        ## Exit script
        echo "Bye."
        exit 0
    elif [[ $CHOOSE == "Install" ]]; then
        ## Install games
        install_menu
    else
        ## Run choosen game
        $CHOOSE
    fi
    CHOOSE=''
    sleep 0.3 # So that you can press Ctrl + C twice to exit the frozen loop.
done