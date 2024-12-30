#!/bin/bash


LOG_FILE="$HOME/Desktop/out.log"
DEBUG_MODE="off"
CLOUD_REPO="https://cristiuntaru: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@github.com/cristiuntaru/proiect-SO1.git"
DIRECTORY="restaurant"


log_message() {
    local MESSAGE="$1"
    local TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "$TIMESTAMP - $MESSAGE" | tee -a "$LOG_FILE"
}


debug_message() {
    if [[ "$DEBUG_MODE" == "on" ]]; then
        local DEBUG_MSG="$1"
        log_message "DEBUG: $DEBUG_MSG"
    fi
}


print_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h, --help         Show this help message"
    echo "  -u, --usage        Provide an overview of how to use the script interactively."
    echo "  --debug=on/off     Enable or disable debugging mode (default: off)."
    exit 0
}


parse_arguments() {
    debug_message "Parsing command-line arguments..."
    OPTIONS=$(getopt -o hu --long help,usage,debug: -- "$@")
    if [[ $? -ne 0 ]]; then
        echo "Invalid arguments. Use -h or --help for usage information."
        exit 1
    fi

    eval set -- "$OPTIONS"

    while true; do
        case "$1" in
            -h|--help)
                print_help
                ;;
            -u|--usage)
                echo "Usage: Run the script and interact with the menu provided."
                exit 0
                ;;
            --debug)
                DEBUG_MODE="$2"
                debug_message "Debug mode set to: $DEBUG_MODE"
                shift 2
                ;;
            --)
                shift
                break
                ;;
        esac
    done
}


menu() {
    debug_message "Se incearca intrarea in meniul principal..."
    PS3="Alegeti o optiune: "
    options=(
        "Gasirea fisierelor mai vechi de o data calendaristica"
        "Mutarea fisierelor"
        "Stergerea periodica a fisierelor"
        "Configurare aplicatie"
        "Backup avansat de fisiere"
        "Iesire din aplicatie"
    )

    select opt in "${options[@]}"; do
        debug_message "User selected option: $opt"
        case $REPLY in
            1) find_files_by_date; break;;
            2) move_files; break;;
            3) schedule_file_deletion; break;;
            4) configure_application; break;;
            5) backup_menu; break;;
            6) exit 0;;
            *) echo "Optiune invalida. Incercati din nou.";;
        esac
    done
}


backup_menu() {
    debug_message "Se incearca intrarea in meniul de backup..."
    PS3="Alegeti tipul de backup: "
    options=(
        "Backup complet pentru gestiunea unui restaurant"
        "Backup pentru meniuri"
        "Backup pentru rezervari"
        "Backup pentru retete"
        "Backup pentru istoricul comenzilor"
        "Backup pentru lista de furnizori"
        "Inapoi la meniul principal"
    )

    select opt in "${options[@]}"; do
        debug_message "User selected backup option: $opt"
        case $REPLY in
            1) backup_directory "restaurant" "backup_restaurant"; break;;
            2) backup_directory "restaurant/meniuri" "backup_restaurant/meniuri"; break;;
            3) backup_directory "restaurant/rezervari" "backup_restaurant/rezervari"; break;;
            4) backup_directory "restaurant/retete" "backup_restaurant/retete"; break;;
            5) backup_directory "restaurant/istoric_comenzi" "backup_restaurant/istoric_comenzi"; break;;
            6) backup_directory "restaurant/lista_furnizori" "backup_restaurant/lista_furnizori"; break;;
            7) menu; break;;
            *) echo "Optiune invalida. Incercati din nou.";;
        esac
    done
}


backup_directory() {
    SOURCE="$1"
    DEST="$2"
    
    if [[ ! -d "$SOURCE" ]]; then
        log_message "Directorul sursa \"$SOURCE\" nu exista. Backup anulat."
        return
    fi

    mkdir -p "$DEST"

    for item in "$SOURCE"/*; do
        local ITEM_NAME=$(basename "$item")
        local TARGET="$DEST/$ITEM_NAME"
        
        if [[ -d "$item" ]]; then
            mkdir -p "$TARGET"
            cp -ru "$item/"* "$TARGET"
        else
            cp -u "$item" "$TARGET"
        fi
    done

    log_message "Backup complet pentru \"$SOURCE\" realizat in \"$DEST\"."
}


configure_application() {
    PS3="Alegeti o optiune de configurare: "
    options=(
        "Stergere fisiere"
        "Redenumire fisiere"
        "Editare continut fisiere"
        "Creare director temporar pentru fisiere mari si mutarea lor (>10k)"
        "Mutare fisiere in functie de extensie"
        "Mutare fisiere mai vechi de o anumita data"
        "Compresie fisiere intr-un singur fisier ZIP"
        "Inapoi la meniul principal"
    )

    select opt in "${options[@]}"; do
        case $REPLY in
            1) 
                echo -n "Introduceti numele directorului din care sa se stearga fisierele: "
                read -r TARGET_DIR
                if [[ -d "$TARGET_DIR" ]]; then
                    find "$TARGET_DIR" -type f -exec rm -f {} \;
                    log_message "Toate fisierele din $TARGET_DIR au fost sterse."
                else
                    echo "Directorul specificat nu exista!"
                fi
                break
                ;;
                
            2)
    		echo -n "Introduceti numele directorului in care sa se redenumeasca fisierele: "
    		read -r TARGET_DIR

    		if [[ ! -d "$TARGET_DIR" ]]; then
        		echo "Directorul specificat nu exista!"
        		return
    		fi

    		echo -n "Introduceti terminatia de adaugat (ex: .old): "
    		read -r EXT

    		find "$TARGET_DIR" -type f ! -name "*${EXT}" -exec bash -c 'mv "$1" "${1}${2}"' _ {} "$EXT" \;
    		log_message "Fisierele din $TARGET_DIR au fost redenumite cu terminatia $EXT."
    		break
    		;;

            3) 
                echo -n "Introduceti numele directorului din care sa se editeze fisierele: "
		read -r TARGET_DIR

		if [[ ! -d "$TARGET_DIR" ]]; then
		    echo "Directorul specificat nu exista!"
		    return
		fi

		echo -n "Introduceti randul pe care doriti sa-l adaugati in fisiere: "
		read -r LINE

		find "$TARGET_DIR" -type f -exec bash -c 'echo "$1" >> "$2"' _ "$LINE" {} \;
		log_message "Randul '$LINE' a fost adaugat in fisierele din $TARGET_DIR."
		break
		;;

            4) 
                echo -n "Introduceti numele directorului in care sa caute fisierele mari: "
                read -r TARGET_DIR
                LARGE_DIR="$TARGET_DIR/Fisiere_Mari(>10k)"
                if [[ -d "$TARGET_DIR" ]]; then
                    mkdir -p "$LARGE_DIR"
                    find "$TARGET_DIR" -type f -size +10k -exec mv {} "$LARGE_DIR/" \;
                    log_message "Fisierele mari au fost mutate in $LARGE_DIR."
                else
                    echo "Directorul specificat nu exista!"
                fi
                break
                ;;
                
            5) 
                echo -n "Introduceti numele directorului in care sa caute fisierele: "
		read -r TARGET_DIR

		if [[ ! -d "$TARGET_DIR" ]]; then
		    echo "Directorul specificat nu exista!"
		    return
		fi

		echo -n "Introduceti extensia fisierelor de mutat (ex: .txt): "
		read -r EXT
		EXT_DIR="$TARGET_DIR/files_${EXT#.}"

		mkdir -p "$EXT_DIR"
		find "$TARGET_DIR" -type f -name "*${EXT}" -exec mv {} "$EXT_DIR/" \;
		log_message "Fisierele cu extensia $EXT au fost mutate in $EXT_DIR."
		break
		;;

            6)
    		echo -n "Introduceti numele directorului in care sa caute fisierele mai vechi: "
    		read -r TARGET_DIR
		
    		if [[ ! -d "$TARGET_DIR" ]]; then
        		echo "Directorul specificat nu exista!"
        		return
    		fi

    		echo -n "Introduceti data (YYYY-MM-DD): "
    		read -r DATE

    		OLD_DIR="$TARGET_DIR/Fisiere_Mai_Vechi"
    		mkdir -p "$OLD_DIR"
    		find "$TARGET_DIR" -type f -not -newermt "$DATE" -exec mv {} "$OLD_DIR/" \;
    		log_message "Fisierele mai vechi de $DATE au fost mutate in $OLD_DIR."
    		break
    		;;

            7) 
    		echo -n "Introduceti numele directorului in care sa se creeze arhiva ZIP: "
    		read -r TARGET_DIR
    		if [[ -d "$TARGET_DIR" ]]; then
        		DIR_NAME=$(basename "$TARGET_DIR")
        		ZIP_NAME="$TARGET_DIR/${DIR_NAME}.zip"
        		zip -r "$ZIP_NAME" "$TARGET_DIR"
        		log_message "Fisierele din $TARGET_DIR au fost arhivate in $ZIP_NAME."
    		else
        		echo "Directorul specificat nu exista!"
    		fi
    		break
    		;;

            8) 
                menu
                break
                ;;
            *) 
                echo "Optiune invalida. Incercati din nou."
                ;;
        esac
    done
}


find_files_by_date() {
    read -p "Introduceti numele directorului: " directory

    if [ -d "$directory" ]; then
        echo "Directorul '$directory' exista."

        read -p "Introduceti data: " date_input
	
	# Format YYYY-MM-DD
        if [[ "$date_input" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            echo "Ati introdus o data calendaristica in format corect: $date_input."

            timestamp=$(date -d "$date_input" +%s 2>/dev/null)
            if [ $? -ne 0 ]; then
                echo "Data introdusa nu este valida."
                return
            fi

            log_message "Se cauta fisierele modificate inainte de: $date_input."
            find "$directory" -type f -not -newermt "$date_input"
        
        # Format DD-MM-YYYY sau MM-DD-YYYY
	elif [[ "$date_input" =~ ^[0-9]{2}-[0-9]{2}-[0-9]{4}$ ]]; then
	    echo "Ati introdus o data in format DD-MM-YYYY sau MM-DD-YYYY: $date_input."
	
	    converted_date=$(date -d "${date_input:6:4}-${date_input:3:2}-${date_input:0:2}" +%Y-%m-%d 2>/dev/null)
	    if [ $? -ne 0 ]; then
	        # Daca esueaza, consideram ca este MM-DD-YYYY
	        converted_date=$(date -d "${date_input:6:4}-${date_input:0:2}-${date_input:3:2}" +%Y-%m-%d 2>/dev/null)
	        if [ $? -ne 0 ]; then
	            echo "Data introdusa nu este valida."
	            return
	        fi
	    fi

	    log_message "Se cauta fisierele modificate inainte de: $converted_date."
	    find "$directory" -type f -not -newermt "$converted_date"

        # Format relativ (1 zi / 2 saptamani / 3 luni)
        elif [[ "$date_input" =~ ^[0-9]+\ (zi|zile|saptamani|saptamana|luni|luna)$ ]]; then
        
            echo "Ati introdus o perioada relativa: $date_input."

            normalized_input=$(echo "$date_input" | sed 's/^1 zi$/1 day/; s/zile/days/; s/saptamani/weeks/; s/^1 saptamana$/1 week/; s/luni/months/; s/^1 luna$/1 month/')

            relative_date=$(date -d "-$normalized_input" +%Y-%m-%d 2>/dev/null)
            if [ $? -ne 0 ]; then
                echo "Perioada introdusa nu este valida."
                return
            fi

            log_message "Se cauta fisierele modificate inainte de: $relative_date."
            find "$directory" -type f -not -newermt "$relative_date"

        else
            echo "Format de data necunoscut."
        fi

    else
        echo "Directorul '$directory' nu exista."
    fi
}


move_files() {
    echo "Alegeti unde doriti sa mutati fisierele:"
    echo "1) Local"
    echo "2) In cloud"
    echo -n "Selectati o optiune (1/2): "
    read -r OPTION

    case "$OPTION" in
        1)
            echo -n "Introduceti directorul sursa: "
            read -r SOURCE

            if [[ ! -d "$SOURCE" ]]; then
                echo "Directorul sursa \"$SOURCE\" nu exista!"
                return
            fi

            echo -n "Introduceti directorul destinatie: "
            read -r DEST

            if [[ ! -d "$DEST" ]]; then
                echo "Directorul destinatie \"$DEST\" nu exista!"
                return
            fi

            mv "$SOURCE"/* "$DEST"

            if [[ $? -eq 0 ]]; then
                log_message "Fisiere mutate cu succes din $SOURCE in $DEST."
            else
                log_message "Eroare la mutarea fisierelor din $SOURCE in $DEST."
            fi
            ;;
        2)
            echo "Mutarea fisierelor in cloud..."
            echo -n "Introduceti directorul sursa: "
            read -r SOURCE

            if [[ ! -d "$SOURCE" ]]; then
                echo "Directorul sursa \"$SOURCE\" nu exista!"
                return
            fi

            if [ -z "$(ls -A "$SOURCE")" ]; then
                echo "Directorul sursa este gol. Nu exista fisiere de mutat."
                return
            fi

            PARENT_DIR=$(pwd)

            cd "$SOURCE" || {
                echo "Nu s-a putut accesa directorul sursa \"$SOURCE\"."
                return
            }

            if [ ! -d ".git" ]; then
                git init
            fi

            git remote add origin "$CLOUD_REPO" 2>/dev/null
            git add .
            git commit -m "Mutare fisiere in cloud"
            git branch -M main
            git pull origin main --rebase
            git push -u origin main

            if [[ $? -eq 0 ]]; then
                log_message "Fisierele din $SOURCE au fost mutate cu succes in cloud."

                cd "$PARENT_DIR" || exit

                echo "Stergere fisiere locale pe rand dupa sincronizarea cu cloud..."
                for file in "$SOURCE"/*; do
                    if [[ -f "$file" ]]; then
                        rm -f "$file"
                        log_message "Fisier sters: $file"
                    fi
                done

                find "$SOURCE" -mindepth 1 -type d -exec rm -rf {} \;

                log_message "Toate fisierele si subdirectoarele locale au fost sterse. Directorul este acum complet gol."
            else
                log_message "Eroare la mutarea fisierelor din $SOURCE in cloud."
            fi
            ;;
        *)
            echo "Optiune invalida. Incercati din nou."
            ;;
    esac
}


schedule_file_deletion() {
    echo -n "Introduceti directorul din care se vor sterge fisierele: "
    read -r TARGET_DIR

    if [[ ! -d "$TARGET_DIR" ]]; then
        echo "Directorul specificat nu exista!"
        return
    fi

    CRON_JOB="0 20 * * 1 find $TARGET_DIR -type f -mtime +60 -exec rm -f {} \;"
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

    if [[ $? -eq 0 ]]; then
        log_message "Stergerea periodica a fost programata pentru directorul $TARGET_DIR."
    else
        log_message "Eroare la programarea stergerii pentru $TARGET_DIR."
    fi
}

# --- Main ---
parse_arguments "$@"
while true; do
    menu
done

