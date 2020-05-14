#!/usr/bin/env bash

function main(){
    
    SCR_PATH="$HOME/.photoshop2linux"
    CACHE_PATH="$HOME/.cache/photoshop2linux"
    
    mkdir -p $SCR_PATH
    mkdir -p $CACHE_PATH
    
    setup_log "================| script exécuté |================"
    
    check_arg $1
    is64

    #vérification que aria2c et wine sont bien installé
    package_installed aria2c
    package_installed wine
    package_installed md5sum
    package_installed winetricks

    #supprime le répertoire wine3.4 si il existe puis le créer
    WINE_PATH="$SCR_PATH/wine-3.4"
    rmdir_if_exist $WINE_PATH

    RESOURCES_PATH="$SCR_PATH/resources"
    WINE_PREFIX="$SCR_PATH/prefix"

    #installe wine 3.4
    install_wine34
    
    #créer un nouveau préfix wine pour photoshop
    rmdir_if_exist $WINE_PREFIX
    
    #exporte les variables nécessaire pour wine 3.4
    export_var
    
    #configure le préfix wine et installe mono et gecko automatiquement
    echo -e "\033[1;93mVeuillez autoriser l'installation automatique des packages mono et gecko\e[0m"
    echo -e "\033[1;93mS'ils ne sont pas déjà installés, cliquez sur le bouton OK\e[0m"
    winecfg 2> "$SCR_PATH/wine-error.log"
    if [ $? -eq 0 ];then
        show_message "Préfix Wine configuré..."
        sleep 5
    else
        error "La configuration du préfix wine à échoué :("
    fi
    
    if [ -f "$WINE_PREFIX/user.reg" ];then
        #ajoute les dll nécessaire
        append_DLL
        sleep 4
        #ajoute le dark mode
        set_dark_mod
    else
        error "user.reg Introuvable :("
    fi
   
    #créer le répertoire des ressources
    rmdir_if_exist $RESOURCES_PATH

    #installe les composant nécessaire avec winetricks
    winetricks atmlib fontsmooth=rgb vcrun2008 vcrun2010 vcrun2012 vcrun2013 vcrun2015 atmlib msxml3 msxml6
    #installe photoshop
    sleep 3
    install_photoshopSE
    sleep 5

    echo -e "\033[1;93mVeuillez séléctionnez \"Windows 7\" comme version de windows wine et cliquez sur OK\e[0m"
    winecfg
    
    replacement

    if [ -d $RESOURCES_PATH ];then
        show_message "Suppression du répertoire des resources"
        rm -rf $RESOURCES_PATH
    else
        error "Dossier des resources Introuvable :("
    fi

    launcher
    show_message "\033[1;33mLorsque vous exécutez Photoshop pour la première fois, cela peut prendre un certain temps\e[0m"
    show_message "Bientôt finis..."
    sleep 30
}

function setup_log(){
    echo -e "$(date) : $@" >> $SCR_PATH/setuplog.log
}

function show_message(){
    echo -e "$@"
    setup_log "$@"
}

function error(){
    echo -e "\033[1;31mErreur:\e[0m $@"
    setup_log "$@"
    exit 1
}

function warning(){
    echo -e "\033[1;33mAttention:\e[0m $@"
    setup_log "$@"
}

function launcher(){
    local launcher_path="$PWD/launcher.sh"
    rmdir_if_exist "$SCR_PATH/launcher"

    if [ -f "$launcher_path" ];then
        show_message "launcher.sh Détecté..."
        cp "$launcher_path" "$SCR_PATH/launcher" || error "Impossible de copier le lanceur"
        chmod +x "$SCR_PATH/launcher/launcher.sh"
    else
        error "launcher.sh Introuvable :("
    fi

    #créer le raccourcis de lancement
    local desktop_entry="$PWD/photoshop.desktop"
    local desktop_entry_dest="/usr/share/applications/photoshop.desktop"
    
    if [ -f "$desktop_entry" ];then
        show_message "Lanceur de Photoshop déja présent..."
        #supprime le lanceur si il est existant
        if [ -f "$desktop_entry_dest" ];then
            show_message "Suppresion du lanceur de Photoshop déja existant..."
            sudo rm "$desktop_entry_dest"
        fi
        sudo cp "$desktop_entry" "/usr/share/applications" || error "Impossible de copier le lanceur de Photoshop :("
        sudo sed -i "s|gictorbit|$HOME|g" "$desktop_entry_dest" || error "Impossible d'éditer le lanceur de Photoshop :("
    else
        error "Lanceur de Photoshop Introuvable :("
    fi

    #créer la commande photoshop
    show_message "Création de la commande de lancement Photoshop..."
    if [ -f "/usr/local/bin/photoshop" ];then
        show_message "Suppresion de la version existante de la commande..."
        sudo rm "/usr/local/bin/photoshop"
    fi
    sudo ln -s "$SCR_PATH/launcher/launcher.sh" "/usr/local/bin/photoshop" || error "Impossible de créer la commande Photoshop :("

    unset desktop_entry desktop_entry_dest launcher_path
}

function replacement(){
    local filename="replacement.tgz"
    local filemd5="6441a8e77c082897a99c2b7b588c9ac4"
    local filelink="https://www.dropbox.com/s/17pv6aezl7wz6gs/replacement.tgz?dl=1"
    local filepath="$CACHE_PATH/$filename"

    download_component $filepath $filemd5 $filelink $filename

    mkdir "$RESOURCES_PATH/replacement"
    show_message "Extraction du composant de remplacement..."
    tar -xzf $filepath -C "$RESOURCES_PATH/replacement"

    local replacefiles=("IconResources.idx" "PSIconsHighRes.dat" "PSIconsLowRes.dat")
    local destpath="$WINE_PREFIX/drive_c/users/$USER/PhotoshopSE/Resources"
    
    for f in "${replacefiles[@]}";do
        local sourcepath="$RESOURCES_PATH/replacement/$f"
        cp -f "$sourcepath" "$destpath" || error "Impossible de copier le fichier de remplacement $f :(..."
    done

    show_message "Composant de remplacement supprimé..."
    unset filename filemd5 filelink filepath
}

function install_photoshopSE(){
    local filename="photoshopCC-V19.1.6-2018x64.tgz"
    local filemd5="b63f6ed690343ee12b6195424f94c33f"
    local filelink="https://www.dropbox.com/s/dwfyzq2ie6jih7g/photoshopCC-V19.1.6-2018x64.tgz?dl=1"
    local filepath="$CACHE_PATH/$filename"

    download_component $filepath $filemd5 $filelink $filename

    mkdir "$RESOURCES_PATH/photoshopCC"
    show_message "extract photoshop..."
    tar -xzf $filepath -C "$RESOURCES_PATH/photoshopCC"

    echo "===============| Photoshop2Linux |===============" >> "$SCR_PATH/wine-error.log"
    show_message "installation de Adobe Photoshop CC 2018..."
    show_message "\033[1;33mS'il vous plaît, ne changer pas le répertoire d'installation de Photoshop\e[0m"

    wine "$RESOURCES_PATH/photoshopCC/photoshop_cc.exe" &>> "$SCR_PATH/wine-error.log" || error "Quelque chose ne c'est pas passer comme prévus lors de l'installation de Photoshop"

    notify-send "L'installation de Adobe Photoshop CC 2018 à réussi" -i "photoshop"
    show_message "Adobe Photoshop CC 2018 installé..."
    unset filename filemd5 filelink filepath
}

function set_dark_mod(){
    echo " " >> "$WINE_PREFIX/user.reg"
    local colorarray=(
        '[Control Panel\\Colors] 1491939580'
        '#time=1d2b2fb5c69191c'
        '"ActiveBorder"="49 54 58"'
        '"ActiveTitle"="49 54 58"'
        '"AppWorkSpace"="60 64 72"'
        '"Background"="49 54 58"'
        '"ButtonAlternativeFace"="200 0 0"'
        '"ButtonDkShadow"="154 154 154"'
        '"ButtonFace"="49 54 58"'
        '"ButtonHilight"="119 126 140"'
        '"ButtonLight"="60 64 72"'
        '"ButtonShadow"="60 64 72"'
        '"ButtonText"="219 220 222"'
        '"GradientActiveTitle"="49 54 58"'
        '"GradientInactiveTitle"="49 54 58"'
        '"GrayText"="155 155 155"'
        '"Hilight"="119 126 140"'
        '"HilightText"="255 255 255"'
        '"InactiveBorder"="49 54 58"'
        '"InactiveTitle"="49 54 58"'
        '"InactiveTitleText"="219 220 222"'
        '"InfoText"="159 167 180"'
        '"InfoWindow"="49 54 58"'
        '"Menu"="49 54 58"'
        '"MenuBar"="49 54 58"'
        '"MenuHilight"="119 126 140"'
        '"MenuText"="219 220 222"'
        '"Scrollbar"="73 78 88"'
        '"TitleText"="219 220 222"'
        '"Window"="35 38 41"'
        '"WindowFrame"="49 54 58"'
        '"WindowText"="219 220 222"'
    )
    for i in "${colorarray[@]}";do
        echo "$i" >> "$WINE_PREFIX/user.reg"
    done
    show_message "Définition du dark mode pour Wine..." 
    unset colorarray
}

function append_DLL(){ 
    local dllarray=(
        '[Software\\Wine\\DllOverrides] 1580889458'
        '#time=1d5dbf9ef00b116'
        '"*atl110"="native,builtin"'
        '"*atl120"="native,builtin"'
        '"*msvcp110"="native,builtin"'
        '"*msvcp120"="native,builtin"'
        '"*msvcr100"="native,builtin"'
        '"*msvcr110"="native,builtin"'
        '"*msvcr120"="native,builtin"'
        '"*msvcr90"="native,builtin"'
        '"*msxml3"="native"'
        '"*msxml6"="native"'
        '"*vcomp110"="native,builtin"'
        '"*vcomp120"="native,builtin"'
        '"atl110"="native,builtin"'
        '"atl80"="native,builtin"'
        '"atl90"="native,builtin"'
        '"msvcp100"="native,builtin"'
        '"msvcp110"="native,builtin"'
        '"msvcp120"="native,builtin"'
        '"msvcr100"="native,builtin"'
        '"msvcr110"="native,builtin"'
        '"msvcr120"="native,builtin"'
        '"msvcr90"="native,builtin"'
        '"msxml3"="native,builtin"'
        '"msxml6"="native,builtin"'
        '"vcomp110"="native,builtin"'
        '"vcomp120"="native,builtin"' 
    )
    show_message "Ajouts des DLLs nécessaires..."
    echo " " >> "$WINE_PREFIX/user.reg"
    for i in ${dllarray[@]};do
        echo "$i" >> "$WINE_PREFIX/user.reg"
    done
    unset dllarray
}

function export_var(){
    export WINEPREFIX="$WINE_PREFIX"
    export PATH="$WINE_PATH/bin:$PATH"
    export LD_LIBRARY_PATH="$WINE_PATH/lib:$LD_LIBRARY_PATH"
    # exportation de WINEDLLOVERRIDES="winemenubuilder.exe=d"
    export WINESERVER="$WINE_PATH/bin/wineserver"
    export WINELOADER="$WINE_PATH/bin/wine"
    export WINEDLLPATH="$WINE_PATH/lib/wine"
    
    show_message "Les variables de Wine ont bien été exporté..."
    local wine_version=$(wine --version)
    
    if [ $wine_version == "wine-3.4" ];then
        show_message "La configuration de Wine à réussi..."
    else
        error "La configuration de Wine à échoué :("
    fi
}


function install_wine34(){
    local filename="wine-3.4.tgz"
    local filepath="$CACHE_PATH/$filename" 
    local filemd5="72b485c28e40bba2b73b0d4c0c29a15f" 
    local filelink="http://www.playonlinux.com/wine/binaries/phoenicis/upstream-linux-amd64/PlayOnLinux-wine-3.4-upstream-linux-amd64.tar.gz"
    download_component $filepath $filemd5 $filelink $filename 
    tar -xzf $filepath -C $WINE_PATH
    show_message "L'installation de Wine à réussi..."
    unset filename filepath filemd5 filelink
}

#les paramètres sont [PATH] [CheckSum] [URL] [FILE NAME]
function download_component(){
    local tout=0
    while true;do
        if [ $tout -ge 2 ];then
            error "Désolé, quelque chose c'est mal passé durant le téléchargement $4"
        fi
        if [ -f $1 ];then
            local FILE_ID=$(md5sum $1 | cut -d" " -f1)
            if [ "$FILE_ID" == $2 ];then
                show_message "\033[1;36m$4\e[0m détécté"
                return 1
            else
                show_message "Le fichier téléchargé est corrompu"
                rm $1 
            fi
        else   
            show_message "Téléchargement de $4 ..."
            aria2c -c -x 8 -d $CACHE_PATH -o $4 $3
            if [ $? -eq 0 ];then
                notify-send "$4 à été téléchargé" -i "download"
            fi
            ((tout++))
        fi
    done    
}

function rmdir_if_exist(){
    if [ -d "$1" ];then
        rm -rf $1
        show_message "\033[0;36m$1\e[0m Le répertoire est déja existant, supression de la version existante..."
    fi
    mkdir $1
    show_message "Création\033[0;36m $1\e[0m du répertoire..."
}

function check_arg(){
    if [ $1 != 0 ]
    then
        error "Il n'y a aucun arguments à inséré, il suffit d'exécuter le script"
    fi
    show_message "Les arguments ont été vérifiés..."
}

function is64(){
    local arch=$(uname -m)
    if [ $arch != "x86_64"  ];then
        warning "Votre configuration d'ordinateur en x86 ne permet pas l'installation de Photoshop"
        read -r -p "Voulez-vous continuez [N/y] " response
        if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]];then
           echo "Au revoir :)"
           exit 0
        fi
    fi
   show_message "L'architecture de l'ordinateur x64 est correcte..."
}

function package_installed(){
    local which=$(which $1 2>/dev/null)
    if [ "$which" == "/usr/bin/$1" ];then
        show_message "La paquet\033[1;36m $1\e[0m est installé..."
    else
        error "Le paquet\033[1;33m $1\e[0m à échoué lors de l'installation.\nS'il vous plaît, veuillez réessayé"
    fi
}

main $# $@
