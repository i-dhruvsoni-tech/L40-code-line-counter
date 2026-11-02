#!/bin/bash
# main.sh – L40 Code Line Counter
# Menu-driven shell script (while loop + case)

cd "$(dirname "$0")" || exit 1
source lib/functions.sh

case "$1" in
    --help)   show_help; exit 0 ;;
    --backup) do_backup; exit 0 ;;
    --cron)   cron_task; exit 0 ;;
    "")       ;;
    *)        echo "Unknown argument: $1"; show_help; exit 1 ;;
esac

while true; do
    echo
    echo "=========================================="
    echo "       L40 – CODE LINE COUNTER            "
    echo "=========================================="
    echo " 1) Count files by extension"
    echo " 2) Lines per language (wc -l)"
    echo " 3) 5 largest files"
    echo " 4) List TODO/FIXME comments (grep -rn)"
    echo " 5) Project stats report"
    echo " 6) View data folder contents"
    echo " 7) Backup data (tar.gz)"
    echo " 8) View activity log"
    echo " 0) Exit"
    echo "------------------------------------------"
    read -rp "Enter choice [0-8]: " ch

    if [[ ! "$ch" =~ ^[0-8]$ ]]; then
        echo "Error: Invalid choice '$ch'. Please enter a number between 0 and 8."
        continue
    fi

    case "$ch" in
        1) feature_1 ;;
        2) feature_2 ;;
        3) feature_3 ;;
        4) feature_4 ;;
        5) feature_5 ;;
        6) view_data ;;
        7) do_backup ;;
        8) view_log ;;
        0) 
            echo "Exiting Code Line Counter. Goodbye!"
            log "application exited cleanly"
            break 
            ;;
    esac
done
