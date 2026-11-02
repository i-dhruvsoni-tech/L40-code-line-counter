#!/bin/bash
# lib/functions.sh – All functions for Code Line Counter
DATA="data/project"
LOG="logs/activity.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $*" >> "$LOG"
}

check_data() {
    if [ ! -d "$DATA" ]; then
        echo "Error: Directory '$DATA' not found!"
        return 1
    fi
}

show_help() {
    echo "Usage: ./main.sh            -> Open the interactive menu"
    echo "       ./main.sh --help     -> Display this help message"
    echo "       ./main.sh --backup   -> Run manual data backup"
    echo "       ./main.sh --cron     -> Execute scheduled cron report"
}

view_data() {
    check_data || return
    echo "Listing contents of $DATA:"
    ls -lh "$DATA"
    log "view_data executed"
}

do_backup() {
    mkdir -p backups
    local f="backups/data_$(date +%Y%m%d_%H%M%S).tar.gz"
    tar -czf "$f" data/
    local size
    size=$(du -h "$f" | cut -f1)
    echo "Backup saved: $f (Size:$size)"
    log "backup created $f"
}

view_log() {
    if [ -f "$LOG" ]; then
        echo "=== Activity Log (Last 15 lines) ==="
        tail -n 15 "$LOG"
    else
        echo "No activity log found."
    fi
}

# FEATURE 1: Count files by extension
feature_1() {
    check_data || return
    echo "========================================"
    echo "  FEATURE 1: File Count by Extension    "
    echo "========================================"
    printf "%-15s %-10s\n" "Extension" "Count"
    printf "%-15s %-10s\n" "---------" "-----"
    
    find "$DATA" -type f -name "*.*" | sed -n 's/..*\.//p' | sort | uniq -c | while read -r count ext; do
        printf "%-15s %-10s\n" ".$ext" "$count"
    done
    
    local no_ext
    no_ext=$(find "$DATA" -type f ! -name "*.*" | wc -l)
    if [ "$no_ext" -gt 0 ]; then
        printf "%-15s %-10s\n" "[no ext]" "$no_ext"
    fi
    echo "========================================"
    log "feature_1 executed: counted files by extension"
}

# FEATURE 2: Lines per language (wc -l)
feature_2() {
    check_data || return
    echo "========================================"
    echo "  FEATURE 2: Total Lines by Language    "
    echo "========================================"
    printf "%-15s %-12s\n" "Extension" "Total Lines"
    printf "%-15s %-12s\n" "---------" "-----------"

    for ext in $(find "$DATA" -type f -name "*.*" | sed -n 's/..*\.//p' | sort -u); do
        local total_lines
        total_lines=$(find "$DATA" -type f -name "*.$ext" -exec wc -l {} + 2>/dev
