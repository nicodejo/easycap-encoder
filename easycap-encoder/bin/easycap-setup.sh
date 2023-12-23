#!/bin/bash
PREFIX="$(dirname $0)"
CONFIG_FILE="${PREFIX}/../etc/easycap_encoder/easycap_encoder.conf"
source <(grep = ${CONFIG_FILE} | tr -d ' ')

zenity  --info --ok-label="Suivant" \
        --width=300 \
        --text=" Bienvenue dans l'enregistreur de votre camescope.\n\n\n Veuillez Connecter votre camescope a cet ordinateur avec la clef EasyCAP.\n\n Nous allons vous demander d'indiquer le nom de votre video a enregistrer dans la prochaine etape."

FILE=$(zenity --title="Nom de votre video" --file-selection --filename="${default_save_dir}" --save --confirm-overwrite --file-filter="*.avi")

case $? in
        1)
              echo "Aucun fichier sélectionné."; exit 0;;
        -1)
              echo "Une erreur inattendue est survenue."; exit 0;;
esac

FORMATED_FILE="${FILE%.avi}.avi"

TIME=$(zenity   --ok-label="Suivant" \
                --forms \
                --title="Duree du film" \
                --text="Saisissez la duree indiquee sur l'ecran de votre camescope." \
                --separator=":" \
                --add-entry="Heure exemple: 01" \
                --add-entry="Minutes exemple: 10")
case $? in
        0)
            [ "${TIME}" == ":" ] && echo "Aucune duree sélectionné." && exit 0;
            [ ${#TIME} -lt 5 ] && zenity --error --text=" La duree actuellement indiquee est '${TIME}'\n Nous attendons un format 'HH:MM'." && exit 0;;

        1)
              echo "Aucune duree sélectionné."; exit 0;;
        -1)
              echo "Une erreur inattendue est survenue."; exit 0;;
esac

FORMATED_TIME="${TIME}:00"


START=$(zenity  --info \
                --ok-label="Continuer" \
                --extra-button="Quitter" \
                --width=300 \
                --text=" Vous avez choisie d'enregistrer votre camescope pour une duree de :\n\n   ${FORMATED_TIME}.\n\n Le fichier ${FORMATED_FILE} sera creer et contiendra cet enregistrement.\n\n\n\n Voulez vous continuer ?")

case $? in
        0)
            [ "${START}" == "Quitter" ] && echo "Quitter." && exit 0;;
            
        1)
              echo "Aucun choix sélectionné."; exit 0;;
        -1)
              echo "Une erreur inattendue est survenue."; exit 0;;
esac



START=$(zenity  --info \
                --ok-label="Continuer" \
                --extra-button="Quitter" \
                --width=300 \
                --text=" Preparez vous a apuyer sur lecture de votre camescope.\n\n Apres avoir cliquer sur [Continuer],\n l'enregistrement commencera automatiquement,\n apres un compte a rebours de ${wait_before_record} secondes.")

case $? in
        0)
            [ "${START}" == "Quitter" ] && echo "Quitter." && exit 0;;
            
        1)
              echo "Aucun choix sélectionné."; exit 0;;
        -1)
              echo "Une erreur inattendue est survenue."; exit 0;;
esac

(
    for i in $(seq 1 $wait_before_record)
    do
        echo "# L'enregistrement commencera dans $(($wait_before_record-$i)) secondes"
        echo $((100/$wait_before_record*$i))
        sleep 1s;
    done
) | zenity  --progress \
            --title="Enregistrement" \
            --text="Compte a rebours" \
            --percentage=0 \
            --width=300 \
            --auto-close

[ $? != 0 ] && zenity   --error \
                        --text="Enregistrement annulée." && exit 0


(mencoder   tv:// -tv \
            driver=v4l2:norm=PAL:width=720:height=576:outfmt=uyvy:device=${device_src}:fps=25:alsa:amode=1:forcechan=2:audiorate=48000:adevice=hw.1,0:forceaudio:immediatemode=0 \
            ${mencoder_opt} \
            -endpos ${FORMATED_TIME} -o ${FORMATED_FILE}.avi) \
    | zenity    --progress \
                --title="Enregistrement en cours ..." \
                --text="l'enregistrement est en cours veullez patienter.\n\n   NE FERMEZ PAS L'ORDINATEUR !\n\n Veuillez patienter !" \
                --percentage=99 \
                --no-cancel \
                --auto-close \
                --pulsate

START=$(zenity  --info \
                --ok-label="Ouvrir" \
                --extra-button="Quitter" \
                --width=300 \
                --text=" Votre enregistrement est termine.\n\n Stoppez la lecture du camescope.\n\n Cliquez sur Ouvrir pour visualiser le fichier de votre enregistrement.")

case $? in
        0)
            [ "${START}" == "Quitter" ] && echo "Quitter." && exit 0;;
            
        1)
              echo "Aucun choix sélectionné."; exit 0;;
        -1)
              echo "Une erreur inattendue est survenue."; exit 0;;
esac

nautilus -w -s "${FILE}" &
exit 0
