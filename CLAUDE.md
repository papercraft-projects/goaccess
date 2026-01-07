# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GoAccess is a real-time web log analyzer written in C. It parses web server logs and generates statistics viewable in a terminal (ncurses), HTML, JSON, or CSV formats. Key features include multi-threaded parsing, WebSocket-based real-time HTML reports, and GeoIP support.

## Build Commands

```bash
# Generate configure script (required after cloning or modifying configure.ac)
autoreconf -fiv

# Configure with common options
./configure                                    # Basic build
./configure --enable-utf8                      # UTF-8 support (ncursesw)
./configure --enable-geoip=mmdb                # GeoIP2 MaxMind support
./configure --enable-debug                     # Debug build
./configure --with-openssl                     # TLS/SSL support
./configure --enable-asan                      # Address Sanitizer

# Build
make

# Install (typically requires sudo)
sudo make install

# Run tests
make check
make distcheck

# Clean
make clean
make distclean   # Also removes generated configure files
```

## Running GoAccess

```bash
# Basic usage with predefined format
./goaccess access.log --log-format=COMBINED

# With virtual host format
./goaccess access.log --log-format=VCOMBINED

# Multi-threaded parsing
./goaccess access.log --log-format=COMBINED -j 4

# HTML output
./goaccess access.log --log-format=COMBINED -o report.html

# JSON output with pretty print
./goaccess access.log --log-format=COMBINED -o report.json --json-pretty-print

# Real-time HTML with WebSocket
./goaccess access.log --log-format=COMBINED -o report.html --real-time-html
```

## Architecture

### Core Data Flow
1. **Log Parsing** (`parser.c`) - Parses log entries according to format specifiers
2. **Storage** (`gkhash.c`, `gkmhash.c`) - In-memory hash tables using `khash.h`
3. **Metrics** (`gstorage.c`) - Aggregates data across 17-19 analysis panels
4. **Output** - Terminal UI (`ui.c`), HTML (`tpl.c`, `output.c`), JSON (`json.c`), CSV (`csv.c`)

### Key Source Files
- `src/goaccess.c` - Main entry point and event loop
- `src/parser.c` - Log parsing engine (handles format specifiers like `%h`, `%r`, `%s`)
- `src/gkhash.c` - Primary hash table storage backend
- `src/gkmhash.c` - Multi-level hash maps for complex metrics
- `src/gstorage.c` - Storage metrics management and panel data
- `src/gdashboard.c` - Dashboard/panel rendering logic
- `src/ui.c` - ncurses terminal interface
- `src/websocket.c` - WebSocket server for real-time HTML
- `src/options.c` - CLI argument parsing
- `src/khash.h` - Header-only hash table library (external)

### Key Data Structures
- `GLogItem` - Parsed log entry (IP, date, request, status, bandwidth, user agent)
- `GLog` - Per-file log state (size, lines processed, errors)
- `GModule` - Analysis panel types (visitors, requests, hosts, browsers, etc.)
- `GKHashStorage` - Main storage container using khash
- `GConf` - Global configuration

### Build-Generated Headers
The build process uses `bin2c` to embed resources into the binary:
- `src/tpls.h` - HTML templates from `resources/tpls.html`
- `src/appjs.h`, `src/chartsjs.h` - JavaScript from `resources/js/`
- `src/appcss.h`, `src/bootstrapcss.h`, `src/facss.h` - CSS from `resources/css/`
- `src/countries110m.h` - GeoJSON for maps

These are generated during build and listed in `CLEANFILES` in `Makefile.am`.

### Conditional Compilation
- `HAVE_GEOLOCATION` - GeoIP support (`geoip1.c` or `geoip2.c`)
- `WITH_SSL` - OpenSSL/TLS support (`wsauth.c`)
- `USE_SHA1` - Bundled SHA1 vs system (NetBSD uses libc)
- `USE_MMAP` - Windows/Cygwin mmap implementation

## Dependencies

**Required:**
- pthread
- ncurses (or ncursesw for UTF-8)

**Optional:**
- libmaxminddb (GeoIP2)
- libGeoIP (legacy GeoIP)
- OpenSSL (TLS/SSL for WebSocket)
- gettext/libintl (i18n)

**Build tools:**
- autoconf 2.69+, automake, gettext, sed, tr

## Code Conventions

- C89/C99 compatible
- MIT License header in all source files
- Memory management via `xmalloc.c` wrappers
- Thread-safe design with pthread
- Compiler warnings enabled: `-Wall -Wextra -Wformat=2 -Wmissing-prototypes -Wstrict-prototypes`
