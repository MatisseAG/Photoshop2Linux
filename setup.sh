#! /usr/bin/env bash

function main(){
    
    #print banner
    banner

    #read inputs
    read_input
    let answer=$?

    case "$answer" in

    1)  
        echo "Lancement de l'installation de Photoshop CC 2018..."
        echo -n "En utilisant winetrick comme utilitaire d'installation..."
        run_script "scripts/PhotoshopSetup.sh" "PhotoshopSetup.sh"
        ;;
    2)  
        echo "Lancement de l'installation de Photoshop CC 2018..."
        echo -n "En utilisant le script customisé comme utilitaire d'installation..."
        run_script "scripts/PhotoshopSetupCustom.sh" "PhotoshopSetupCustom.sh"
        ;;
    3)  
        echo -n "Lancement de l'installation de Adobe Camera Raw v12..."
        run_script "scripts/cameraRawInstaller.sh" "cameraRawInstaller.sh"
        ;;
    4)  
        echo "Lancement de winecfg..."
        echo -n "Ouverture de la configuration du disque virtuel..."
        run_script "scripts/winecfg.sh" "winecfg.sh"
        ;;
    5)  
        echo -n "Désinstallation de Photoshop......"
        run_script "scripts/uninstaller.sh" "uninstaller.sh"
        ;;
    6)  
        echo "Fermeture de l'installateur..."
        exitScript
        ;;
    esac

}

#argumaents 1=script_path 2=script_name 
function run_script(){
    local script_path=$1
    local script_name=$2

    wait_second 5
    if [ -f "$script_path" ];then
        echo "$script_path Trouvé..."
        chmod +x "$script_path"
    else
        error "$script_name Non trouvé..."    
    fi
    cd "./scripts/" && sh $script_name
    unset script_path
}

function wait_second(){
    for (( i=0 ; i<$1 ; i++ ));do
        echo -n "."
        sleep 1
    done
    echo ""
}

function read_input(){
    while true ;do
        read -p "[Choissisez une option]$ " choose
        if [[ "$choose" =~ (^[1-6]$) ]];then
            break
        fi
        warning "Choissisez un nombre entre 1 et 6 qui correspond à l'action que vous voulez effectuer"
    done

    return $choose
}

function exitScript(){
    echo "Au revoir :)"
}

function banner(){
    local banner_path="$PWD/images/banner"
    if [ -f $banner_path ];then 
        clear && echo ""
        cat $banner_path
        echo ""
    else
        error "Bannière non trouvé..."
    fi
    unset banner_path
}

function error(){
    echo -e "\033[1;31merror:\e[0m $@"
    exit 1
}

function warning(){
    echo -e "\033[1;33mWarning:\e[0m $@"
}

main
