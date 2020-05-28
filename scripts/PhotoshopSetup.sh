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

main $# $@
