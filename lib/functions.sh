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
    echo "Backup saved: $f (Size: $size)"
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

# ------------------------------------------------------------
# FEATURE 1: Count files by extension
# ------------------------------------------------------------
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

# ------------------------------------------------------------
# FEATURE 2: Lines per language (wc -l)
# ------------------------------------------------------------
feature_2() {
    check_data || return
    echo "========================================"
    echo "  FEATURE 2: Total Lines by Language    "
    echo "========================================"
    printf "%-15s %-12s\n" "Extension" "Total Lines"
    printf "%-15s %-12s\n" "---------" "-----------"

    for ext in $(find "$DATA" -type f -name "*.*" | sed -n 's/..*\.//p' | sort -u); do
        local total_lines
        total_lines=$(find "$DATA" -type f -name "*.$ext" -exec wc -l {} + 2>/dev/null | tail -n 1 | awk '{print $1}')
        printf "%-15s %-12s\n" ".$ext" "$total_lines"
    done
    echo "========================================"
    log "feature_2 executed: lines per language"
}

# ------------------------------------------------------------
# FEATURE 3: 5 largest files
# ------------------------------------------------------------
feature_3() {
    check_data || return
    echo "========================================"
    echo "  FEATURE 3: Top 5 Largest Files        "
    echo "========================================"
    printf "%-8s %-12s %-30s\n" "Lines" "Disk Size" "File Name"
    printf "%-8s %-12s %-30s\n" "-----" "---------" "---------"

    find "$DATA" -type f -exec wc -l {} + | grep -v ' total$' | sort -nr | head -n 5 | while read -r lines path; do
        local dsize
        dsize=$(du -h "$path" | cut -f1)
        local fname
        fname=$(basename "$path")
        printf "%-8s %-12s %-30s\n" "$lines" "$dsize" "$fname"
    done
    echo "========================================"
    log "feature_3 executed: top 5 largest files"
}

# ------------------------------------------------------------
# FEATURE 4: List TODO/FIXME comments
# ------------------------------------------------------------
feature_4() {
    check_data || return
    echo "========================================"
    echo "  FEATURE 4: Pending TODO/FIXME Comments"
    echo "========================================"
    
    local matches
    matches=$(grep -rnEI "TODO|FIXME" "$DATA")
    
    if [ -z "$matches" ]; then
        echo "No TODO or FIXME comments found in $DATA."
    else
        grep -rnEI --color=always "TODO|FIXME" "$DATA"
        local total
        total=$(echo "$matches" | wc -l)
        echo "----------------------------------------"
        echo "Total actionable comments found: $total"
    fi
    echo "========================================"
    log "feature_4 executed: listed TODO/FIXME comments"
}

# ------------------------------------------------------------
# FEATURE 5: Project stats report
# ------------------------------------------------------------
feature_5() {
    check_data || return
    mkdir -p reports
    local report_file="reports/project_stats_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "=================================================="
        echo "         PROJECT CODE ANALYSIS REPORT             "
        echo "Generated on : $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Target Folder: $DATA"
        echo "=================================================="
        echo
        echo "1. OVERALL METRICS:"
        echo "   - Total Files        : $(find "$DATA" -type f | wc -l)"
        echo "   - Total Lines of Code: $(find "$DATA" -type f -exec cat {} + | wc -l)"
        echo "   - Total Disk Usage   : $(du -sh "$DATA" | cut -f1)"
        echo "   - Pending Tasks      : $(grep -rE "TODO|FIXME" "$DATA" 2>/dev/null | wc -l)"
        echo
        echo "2. FILE BREAKDOWN BY EXTENSION:"
        find "$DATA" -type f -name "*.*" | sed -n 's/..*\.//p' | sort | uniq -c | awk '{printf "   %-10s: %d file(s)\n", "."$2, $1}'
        echo
        echo "3. TOP 5 LARGEST FILES (BY LINES):"
        find "$DATA" -type f -exec wc -l {} + | grep -v ' total$' | sort -nr | head -n 5 | awk '{printf "   %-8d lines -> %s\n", $1, $2}'
        echo
        echo "=================================================="
    } | tee "$report_file"

    echo
    echo "Report saved successfully to: $report_file"
    log "feature_5 executed: generated report $report_file"
}

# ------------------------------------------------------------
# CRON TASK
# ------------------------------------------------------------
cron_task() {
    check_data || return
    mkdir -p reports logs
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local cron_report="reports/cron_stats_${timestamp}.txt"
    
    {
        echo "=== AUTOMATED CRON AUDIT REPORT ==="
        echo "Execution Date : $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Total Files    : $(find "$DATA" -type f | wc -l)"
        echo "Total Lines    : $(find "$DATA" -type f -exec cat {} + | wc -l)"
        echo "Pending Issues : $(grep -rE "TODO|FIXME" "$DATA" 2>/dev/null | wc -l)"
        echo "==================================="
    } > "$cron_report"

    echo "$(date '+%Y-%m-%d %H:%M:%S') | CRON task executed: generated $cron_report" >> logs/cron.log
    log "cron_task executed successfully"
}
