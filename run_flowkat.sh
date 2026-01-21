#!/bin/bash

# FlowKat GoAccess Interactive Runner
# Provides a menu-driven interface to run the FlowKat GoAccess Docker container.

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Banner (Matched with banner.txt)
show_banner() {
    clear
    echo -e "${CYAN}"
    cat banner.txt 2>/dev/null || echo "FlowKat Monitoring Solution"
    echo -e "${NC}"
    echo -e "${GREEN}--- FlowKat Interactive Runner ---${NC}\n"
}

# 0. Handle Arguments
IS_WEB_MODE=false
WEB_PORT=8080
WS_PORT=7890

if [[ "$1" == "webmode" ]]; then
    IS_WEB_MODE=true
    if [[ -n "$2" ]]; then
        WEB_PORT="$2"
    fi
    # If standard GoAccess port is used for web, shift WebSocket port
    if [[ "$WEB_PORT" == "7890" ]]; then
        WS_PORT=7891
    fi
fi

# Check if image exists
if [[ "$(docker images -q goaccess-flowkat 2> /dev/null)" == "" ]]; then
    echo -e "${RED}Error: Docker image 'goaccess-flowkat' not found.${NC}"
    echo "Please run ./build_docker.sh first."
    exit 1
fi

# 1. Select Log File
show_banner
echo -e "${YELLOW}[Step 1] Select Log File${NC}"
LOG_FILES=($(ls *.log 2>/dev/null))

if [ ${#LOG_FILES[@]} -eq 0 ]; then
    echo "No .log files found in current directory."
    read -p "Enter path to log file manually: " SELECTED_LOG
else
    PS3="Select a log file (or 0 to manual entry): "
    select log in "${LOG_FILES[@]}"; do
        if [ "$REPLY" == "0" ]; then
            read -p "Enter path to log file: " SELECTED_LOG
            break
        elif [ -n "$log" ]; then
            SELECTED_LOG="$log"
            break
        fi
    done
fi

if [ ! -f "$SELECTED_LOG" ]; then
    echo -e "${RED}Error: File '$SELECTED_LOG' not found.${NC}"
    exit 1
fi

# 2. Select Log Format
show_banner
echo -e "${YELLOW}[Step 2] Select Log Format${NC}"
echo "1) Nginx/Apache VCombined (with Virtual Host) - Recommended"
echo "2) Nginx/Apache Combined (Standard)"
echo "3) Common Log Format (CLF)"
echo "4) W3C (IIS)"
echo "5) Amazon S3"
echo "6) Google Cloud Storage"
read -p "Choose a format [1-6, default 1]: " FORMAT_CHOICE

case $FORMAT_CHOICE in
    1) SELECTED_FORMAT="VCOMBINED" ;;
    2) SELECTED_FORMAT="COMBINED" ;;
    3) SELECTED_FORMAT="COMMON" ;;
    4) SELECTED_FORMAT="W3C" ;;
    5) SELECTED_FORMAT="S3" ;;
    6) SELECTED_FORMAT="GCS" ;;
    *) SELECTED_FORMAT="VCOMBINED" ;;
esac

# 3. Select Run Mode
show_banner
echo -e "${YELLOW}[Step 3] Select Run Mode${NC}"
echo "1) Terminal Dashboard (Interactive TUI)"
echo "2) Static HTML Report (output to report.html)"
echo "3) Real-time HTML Report (WebSocket on port 7890)"
echo "4) FlowKat Native Analysis (Built-in user/cafe detection)"
echo "5) Filter by ID/User (Keyword search)"
echo "6) Custom Arguments"

if [ "$IS_WEB_MODE" = true ]; then
    RUN_MODE=3
    echo -e "${CYAN}Web Mode enabled via argument. Using port $WEB_PORT.${NC}"
else
    read -p "Choose an option [1-6]: " RUN_MODE
fi

# 4. Execution Logic
LOG_DIR=$(pwd)
LOG_FILE_NAME=$(basename "$SELECTED_LOG")
ABS_LOG_PATH=$(realpath "$SELECTED_LOG")
ABS_LOG_DIR=$(dirname "$ABS_LOG_PATH")

case $RUN_MODE in
    1)
        echo -e "${GREEN}Starting Terminal Dashboard...${NC}"
        docker run --rm -it -v "$ABS_LOG_DIR":/logs goaccess-flowkat "/logs/$LOG_FILE_NAME" --log-format="$SELECTED_FORMAT" --date-format='%d/%b/%Y' --time-format='%H:%M:%S'
        ;;
    2)
        echo -e "${GREEN}Generating report.html...${NC}"
        docker run --rm -v "$ABS_LOG_DIR":/logs -v "$LOG_DIR":/output goaccess-flowkat "/logs/$LOG_FILE_NAME" --log-format="$SELECTED_FORMAT" --date-format='%d/%b/%Y' --time-format='%H:%M:%S' -o /output/report.html
        echo -e "${GREEN}✔ Done! report.html has been created.${NC}"
        ;;
    3)
        if [ "$IS_WEB_MODE" = true ] || { read -p "Start a web server to view the report? (y/n) [default y]: " START_WEB && [[ $START_WEB != "n" ]]; }; then
            if [ "$IS_WEB_MODE" = false ]; then
                read -p "Enter web server port [default 8080]: " USER_PORT
                WEB_PORT=${USER_PORT:-8080}
            fi

            # Check for 7890 conflict again if set via prompt
            if [[ "$WEB_PORT" == "7890" ]]; then WS_PORT=7891; fi

            echo -e "${GREEN}Starting Nginx Web Server on port $WEB_PORT...${NC}"
            # Run Nginx in background to serve the current directory
            docker run -d --rm --name flowkat-web -p "$WEB_PORT":80 -v "$LOG_DIR":/usr/share/nginx/html:ro nginx:alpine > /dev/null
            echo -e "${CYAN}--------------------------------------------------${NC}"
            echo -e "${CYAN}✔ Report URL: http://localhost:$WEB_PORT/report.html${NC}"
            echo -e "${CYAN}--------------------------------------------------${NC}"

            # Setup cleanup handler for the web server on script exit
            trap "echo -e '\n${YELLOW}Stopping web server...${NC}'; docker stop flowkat-web > /dev/null 2>&1; exit" INT TERM
        fi

        echo -e "${GREEN}Starting GoAccess Real-time server (WS Port: $WS_PORT)...${NC}"
        docker run --rm -it -p "$WS_PORT":"$WS_PORT" -v "$ABS_LOG_DIR":/logs -v "$LOG_DIR":/output goaccess-flowkat \
            "/logs/$LOG_FILE_NAME" --log-format="$SELECTED_FORMAT" --date-format='%d/%b/%Y' --time-format='%H:%M:%S' -o /output/report.html \
            --real-time-html --port="$WS_PORT"

        # Cleanup: Stop web server if it's running
        if docker ps --format '{{.Names}}' | grep -q 'flowkat-web'; then
            echo -e "${YELLOW}Cleaning up web server...${NC}"
            docker stop flowkat-web > /dev/null
        fi
        ;;
    4)
        echo -e "${GREEN}Running FlowKat Native Analysis...${NC}"
        echo -e "${YELLOW}Extracting Identities directly from C binary...${NC}"
        docker run --rm -it -v "$ABS_LOG_DIR":/logs -v "$LOG_DIR":/output goaccess-flowkat "/logs/$LOG_FILE_NAME" --log-format="$SELECTED_FORMAT" --date-format='%d/%b/%Y' --time-format='%H:%M:%S' -o /output/report.html
        echo -e "${GREEN}✔ Native Analysis Done! Check 'FlowKat Identities' panel in report.html.${NC}"
        ;;
    5)
        read -p "Enter Keyword/ID to filter (e.g. 20181601): " KEYWORD
        echo -e "${GREEN}Filtering logs for '$KEYWORD'...${NC}"
        grep "$KEYWORD" "$SELECTED_LOG" | docker run --rm -i -v "$LOG_DIR":/output goaccess-flowkat - --log-format="$SELECTED_FORMAT" --date-format='%d/%b/%Y' --time-format='%H:%M:%S' -o /output/report.html
        echo -e "${GREEN}✔ Filtered Analysis Done! Check report.html.${NC}"
        ;;
    6)
        read -p "Enter extra arguments: " EXTRA_ARGS
        docker run --rm -it -v "$ABS_LOG_DIR":/logs goaccess-flowkat "/logs/$LOG_FILE_NAME" --date-format='%d/%b/%Y' --time-format='%H:%M:%S' $EXTRA_ARGS
        ;;
    *)
        echo -e "${RED}Invalid option.${NC}"
        exit 1
        ;;
esac
