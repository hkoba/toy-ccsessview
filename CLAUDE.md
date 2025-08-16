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

### Core Components

1. **CCSessions.pm** - Backend module for reading and parsing Claude session JSONL files
   - Handles file discovery, caching, and JSON parsing
   - Provides methods for listing projects, sessions, and reading individual messages

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
- `.yatt` files contain templates with multiple pages
- Entity references like `&yatt:backend();` call Perl code
- Widget declarations like `<!yatt:page>` define page components
- Built-in entities: `decode_json`, `decode_utf8` for data processing

### Session File Structure

Claude sessions are stored as JSONL (JSON Lines) files:
- One JSON object per line
- Each line represents a message or event in the conversation
- Files located in: `$CLAUDE_PROJECTS_DIR/{project-name}/{session-id}.jsonl`

## Development Notes

### Adding Features

- Backend logic goes in `lib/CCSessions.pm`
- UI templates in `public/index.yatt`
- New pages can be added as `<!yatt:page>` sections

### Content Type Rendering

The viewer supports custom rendering for different content types:
- Define widgets like `<!yatt:widget content_type__text>` for specific types
- Falls back to plain text display for unknown types