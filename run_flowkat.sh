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
echo "1) Nginx/Apache Combined (Standard)"
echo "2) Nginx/Apache VCombined (with Virtual Host)"
echo "3) Common Log Format (CLF)"
echo "4) W3C (IIS)"
echo "5) Amazon S3"
echo "6) Google Cloud Storage"
read -p "Choose a format [1-6, default 1]: " FORMAT_CHOICE

case $FORMAT_CHOICE in
    2) SELECTED_FORMAT="VCOMBINED" ;;
    3) SELECTED_FORMAT="COMMON" ;;
    4) SELECTED_FORMAT="W3C" ;;
    5) SELECTED_FORMAT="S3" ;;
    6) SELECTED_FORMAT="GCS" ;;
    *) SELECTED_FORMAT="COMBINED" ;;
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
read -p "Choose an option [1-6]: " RUN_MODE

# 4. Execution Logic
LOG_DIR=$(pwd)
LOG_FILE_NAME=$(basename "$SELECTED_LOG")
ABS_LOG_PATH=$(realpath "$SELECTED_LOG")
ABS_LOG_DIR=$(dirname "$ABS_LOG_PATH")

case $RUN_MODE in
    1)
        echo -e "${GREEN}Starting Terminal Dashboard...${NC}"
        docker run --rm -it -v "$ABS_LOG_DIR":/logs goaccess-flowkat "/logs/$LOG_FILE_NAME" --log-format="$SELECTED_FORMAT"
        ;;
    2)
        echo -e "${GREEN}Generating report.html...${NC}"
        docker run --rm -v "$ABS_LOG_DIR":/logs -v "$LOG_DIR":/output goaccess-flowkat "/logs/$LOG_FILE_NAME" --log-format="$SELECTED_FORMAT" -o /output/report.html
        echo -e "${GREEN}✔ Done! report.html has been created.${NC}"
        ;;
    3)
        echo -e "${GREEN}Starting Real-time HTML server on port 7890...${NC}"
        echo -e "${YELLOW}Access via browser after generation.${NC}"
        docker run --rm -it -p 7890:7890 -v "$ABS_LOG_DIR":/logs -v "$LOG_DIR":/output goaccess-flowkat "/logs/$LOG_FILE_NAME" --log-format="$SELECTED_FORMAT" -o /output/report.html --real-time-html
        ;;
    4)
        echo -e "${GREEN}Running FlowKat Native Analysis...${NC}"
        echo -e "${YELLOW}Extracting Identities directly from C binary...${NC}"
        docker run --rm -it -v "$ABS_LOG_DIR":/logs -v "$LOG_DIR":/output goaccess-flowkat "/logs/$LOG_FILE_NAME" --log-format="$SELECTED_FORMAT" -o /output/report.html
        echo -e "${GREEN}✔ Native Analysis Done! Check 'FlowKat Identities' panel in report.html.${NC}"
        ;;
    5)
        read -p "Enter Keyword/ID to filter (e.g. 20181601): " KEYWORD
        echo -e "${GREEN}Filtering logs for '$KEYWORD'...${NC}"
        grep "$KEYWORD" "$SELECTED_LOG" | docker run --rm -i -v "$LOG_DIR":/output goaccess-flowkat - --log-format="$SELECTED_FORMAT" -o /output/report.html
        echo -e "${GREEN}✔ Filtered Analysis Done! Check report.html.${NC}"
        ;;
    6)
        read -p "Enter extra arguments: " EXTRA_ARGS
        docker run --rm -it -v "$ABS_LOG_DIR":/logs goaccess-flowkat "/logs/$LOG_FILE_NAME" $EXTRA_ARGS
        ;;
    *)
        echo -e "${RED}Invalid option.${NC}"
        exit 1
        ;;
esac
