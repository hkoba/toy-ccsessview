# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Claude Code session viewer (`toy-ccsessview`) - a Perl/PSGI web application for browsing Claude Code session JSON files stored locally. It provides a web interface to view and navigate through Claude conversation history.

## Key Commands

### Running the Application

```bash
# Using the CLI script (preferred)
./ccsessview [CLAUDE_PROJECTS_DIR]

# Using plackup directly
plackup app.psgi

# With custom Claude projects directory
CLAUDE_PROJECTS_DIR=~/.claude/projects plackup app.psgi
```

### Development Server

```bash
# Default development server on port 5000
plackup app.psgi

# Custom port
plackup -p 8080 app.psgi
```

## Architecture Overview

This project is built with YATT::Lite, a template engine and web framework. The data analysis and extraction is handled by the `lib/CCSessions.pm` module.

### Core Components

1. **CCSessions.pm** - Backend module for reading and parsing Claude session JSONL files
   - Handles file discovery, caching, and JSON parsing
   - Provides methods for listing projects, sessions, and reading individual messages
   - Designed as a JSON-oriented OO Modulino based on `MOP4Import::Base::CLI_JSON`
   - Can be executed directly from command line to test any method

2. **app.psgi** - PSGI application entry point
   - Uses YATT::Lite web framework
   - Mounts CCSessions as an entity for template access

3. **public/index.yatt** - Main template file
   - Contains three pages: project list, session list, and message viewer
   - Uses YATT template syntax for dynamic content

4. **ccsessview** - CLI wrapper script
   - Provides convenient command-line interface
   - Sets up environment and launches Plack runner

### Data Flow

1. **Session Discovery**: Scans `CLAUDE_PROJECTS_DIR` (default: `~/.claude/projects`) for project directories
2. **File Format**: Reads `.jsonl` files containing Claude conversation messages
3. **Caching**: Maintains in-memory cache of session positions for fast navigation
4. **Rendering**: Uses YATT templates to display formatted messages with proper content types

### YATT Template System

This project uses YATT::Lite templating framework. Key concepts:

#### Widget and Page Structure
- `.yatt` files contain templates with multiple widgets
- **Widget**: A template component defined with `<!yatt:widget>` or `<!yatt:page>`
- **Page**: A public widget directly accessible from web requests, defined with `<!yatt:page>`
- The default widget (without name) serves as the index page
- Widget paths use `:` separator (e.g., `index:session` means session page in index.yatt)
- **Same-file widget calls**: Within the same `.yatt`/`.ytmpl` file, the filename prefix can be omitted
  - Example: In `index.yatt`, use `<yatt:content_type__text/>` instead of `<yatt:index:content_type__text/>`

#### Template Access Control
- **Public templates**: `*.yatt` files under `public/` are accessible from web, showing the default widget
- **Private templates**: `*.ytmpl` files are private and cannot be accessed directly, even if placed in `public/`
- **Page access via URL**: To access a specific page (public widget), use request parameters:
  - `~~=pagename` or `~pagename=value` - Both forms access the specified page (functionally equivalent)
  - Additional parameters are passed with `;` separator
  - Example: `?~~=session;id=123` accesses the `session` page with `id` parameter
  - Example: `?~~=show;id=123;ix=0` accesses the `show` page with `id` and `ix` parameters

#### Template Syntax
- Entity references like `&yatt:backend();` call Perl code
- Widget declarations like `<!yatt:page>` define page components
- Built-in entities: `decode_json`, `decode_utf8` for data processing

### Session File Structure

Claude sessions are stored as JSONL (JSON Lines) files:
- One JSON object per line
- Each line represents a message or event in the conversation
- Files located in: `$CLAUDE_PROJECTS_DIR/{project-name}/{session-id}.jsonl`

## Development Notes

### Inspecting YATT Templates

Use `YATT::Lite::Inspector` to analyze the web application structure:

```bash
# List all widgets in the application
./lib/YATT/Lite/Inspector.pm list_widgets

# Filter widgets by path pattern
./lib/YATT/Lite/Inspector.pm list_widgets 'index:*'

# Output includes: name, kind (page/widget), path, and args
```

Inspector.pm is an OO Modulino that loads `app.psgi` into memory and reads actual configuration like `doc_root` to provide accurate widget information. The output is in NDJSON format showing widget metadata.

### Testing CCSessions.pm Methods

CCSessions.pm is a Modulino that can be executed directly from command line:

```bash
# List all projects
./lib/CCSessions.pm project_list

# List sessions for a specific project (returns FileInfo records as NDJSON)
./lib/CCSessions.pm session_list $(./lib/CCSessions.pm project_list | head -1)

# Get help
./lib/CCSessions.pm --help

# Execute any method (default output is NDJSON)
./lib/CCSessions.pm method_name args...

# Change output format if needed
./lib/CCSessions.pm --output=tsv method_name args...
```

This allows direct testing of any method without writing Perl scripts, making development and debugging easier.

### Adding Features

- Backend logic goes in `lib/CCSessions.pm`
- UI templates in `public/index.yatt`
- New pages can be added as `<!yatt:page name>` sections
- New widgets can be added as `<!yatt:widget name>` sections
- All widgets in `index.yatt` are accessible with `index:` prefix

### Content Type Rendering

The viewer supports custom rendering for different content types:
- Define widgets like `<!yatt:widget content_type__text>` for specific types
- Falls back to plain text display for unknown types