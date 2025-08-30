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

##### Variable Types and Assignment
- **scalar (value)**: `<yatt:my var:value="..."/>`
- **list**: `<yatt:my var:list="..."/>`
  - List assignment allows direct foreach iteration without lexpand
  - Works when backend method uses `wantarray` to return list/array

##### Array and Hash Access
- **Array element access**: `&yatt:ARRAY[:INDEX];`
  - Example: `&yatt:items[:ix];` accesses element at index `ix`
- **Hash element access**: `&yatt:HASH{KEY};`
- **Nested expressions**: Use `:` prefix for variables inside expressions
  - Example: `&yatt:lexpand(:items);` expands the `items` variable

##### Entity Macros
- `&yatt:lexpand(:ARRAY_EXPR);` - Expands array expression (applies `@{ARRAY}` in Perl)
  - Use with scalar variables containing array refs
  - Not needed when using list-type variables

##### Conditional Statements
- `<yatt:if "condition">...action...</yatt:if>`
- `<:yatt:else/>...alternative action...`
- `<:yatt:else if="condition"/>...conditional action...`
- Note: else if uses `<:yatt:else if="..."/>` not `<:yatt:elif/>`

### Session File Structure

Claude sessions are stored as JSONL (JSON Lines) files:
- One JSON object per line
- Each line represents a message or event in the conversation
- Files located in: `$CLAUDE_PROJECTS_DIR/{project-name}/{session-id}.jsonl`

## Development Notes

### Static Code Analysis

Before running the application, always perform static checks:

#### Perl Module Checking
```bash
# Check Perl modules with perlminlint
perlminlint lib/CCSessions.pm
# Expected output: "Module CCSessions is OK"
```

#### Template Checking
```bash
# Check YATT templates with yatt lint
./lib/YATT/scripts/yatt lint public/index.yatt
# Silent output means success
```

#### Debugging Template Compilation Errors

YATT template errors come in two types:
1. **YATT syntax errors** - Issues with YATT markup itself
2. **Perl code errors** - Issues in the transpiled Perl code

For Perl code errors, use `yatt genperl` to see the transpiled code:
```bash
# Generate Perl code for entire template file
./lib/YATT/scripts/yatt genperl public/index.yatt

# Extract code for a specific widget/page
./lib/YATT/scripts/yatt genperl public/index.yatt | perl -nle '/^sub render_session \{/ .. /^\}/ and print'

# General pattern: sub render_$widgetName
./lib/YATT/scripts/yatt genperl public/index.yatt | perl -nle '/^sub render_WIDGETNAME \{/ .. /^\}/ and print'
```

This helps identify the exact line causing the error in the generated Perl code.

Always run these static checks before starting the development server with `plackup app.psgi`.

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

#### Important: CLI_JSON Argument Passing

When testing methods with JSON arguments, pass them as command line arguments, NOT via stdin:

```bash
# CORRECT - Pass JSON as command line arguments
./lib/CCSessions.pm parse_item__user '{}' '{"type":"user","message":{"content":"test"}}'

# INCORRECT - Do NOT use stdin
echo '{}' | ./lib/CCSessions.pm parse_item__user /dev/stdin '...'  # This will fail
```

#### CLI_JSON Development Best Practices

**Return Objects (HASHes) Instead of Strings**

When developing with CLI_JSON, prefer returning Perl HASH references (objects) over simple strings:

```perl
# GOOD - Returns a HASH with multiple fields
sub my_method {
  (my MY $self, my $item) = @_;
  $item->{field1} = 'value1';
  $item->{field2} = 'value2';
  $item;  # Returns the entire object
}

# LESS USEFUL - Returns only a single value
sub my_method {
  (my MY $self, my $item) = @_;
  $item->{field1} = 'value1';
  $item->{field1};  # Returns only one field
}
```

Benefits of returning objects:
- **Complete visibility**: All fields are visible in the JSON output
- **Easier debugging**: Can see all data transformations at once
- **Better testing**: Can verify multiple fields in a single call
- **Field preservation**: Existing fields in input objects are retained

Example output comparison:
```bash
# With object return - shows all fields
$ ./lib/CCSessions.pm parse_item__user '{"pos":123}' '{"type":"user",...}'
{"pos":123,"role":"user","summary":"...","type":"user"}

# With string return - shows only one value
"..."
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

## Current Improvement Plan

### Session List Enhancement (In Progress)

The session page currently shows only index numbers. We're enhancing it to display summaries for each session item.

#### Implementation Strategy

1. **Data Structure Update**
   - Current: `_session_cache` stores only byte positions
   - New: Store both positions and extracted metadata (type, role, summary)
   - Define `SessionItemInfo` type with fields: pos, type, role/tool, summary

2. **Summary Extraction Logic**
   - **user**: "User: " + first 50 chars of content
   - **assistant**: "Claude: " + first 50 chars of content/text
   - **tool_use**: "Tool: " + tool name
   - **tool_result**: "Result: " + success/failure status
   - **Other types**: Display type name directly

3. **Backend Changes**
   - Modify `scan_session` method to decode JSON and extract summaries
   - Maintain backward compatibility for existing index access
   - Cache structure: Array of hash refs with metadata

4. **Frontend Updates**
   - Update `<!yatt:page session>` to display summaries
   - Add visual differentiation by type (icons/colors)
   - Show preview text for each session item