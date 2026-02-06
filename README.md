# CopperMine

The official documentation website for the [CopperMoon](https://github.com/coppermoondev/coppermoon) ecosystem — built entirely with CopperMoon itself.

## Overview

CopperMine is a comprehensive documentation portal that covers the entire CopperMoon stack: runtime, web framework, ORM, templating, tooling, and community packages. It features a custom Markdown-to-HTML renderer written in pure Lua, a responsive sidebar with collapsible sections, table of contents with scroll spy, and a search API.

The site itself serves as a real-world reference implementation demonstrating best practices with HoneyMoon, Vein, Tailwind, Ember, and Lantern.

## Tech Stack

| Component | Package | Role |
|-----------|---------|------|
| Runtime | CopperMoon | Lua 5.4 on Rust |
| Web Framework | [honeymoon](https://packages.coppermoon.dev/packages/honeymoon) | Routing, middleware, sessions |
| Templates | [vein](https://packages.coppermoon.dev/packages/vein) | Layouts, partials, filters |
| CSS | [tailwind](https://packages.coppermoon.dev/packages/tailwind) | Utility-first styling (CopperMoon preset) |
| Logging | [ember](https://packages.coppermoon.dev/packages/ember) | Structured console/file logging |
| DevTools | [lantern](https://packages.coppermoon.dev/packages/lantern) | Debug panel (development only) |

## Project Structure

```
coppermine/
├── app.lua                  # Entry point — routes, markdown filter, config
├── harbor.toml              # Package manifest & dependencies
├── Shipyard.toml            # Dev server configuration
├── content/                 # Markdown documentation (87 files)
│   ├── getting-started/     # Installation, quick start, project structure
│   ├── coppermoon/          # Runtime docs (modules, HTTP, fs, JSON, time)
│   ├── honeymoon/           # Web framework (routing, middleware, auth, etc.)
│   ├── vein/                # Template engine (syntax, filters, layouts)
│   ├── freight/             # ORM (models, queries, relationships, migrations)
│   ├── harbor/              # Package manager (installing, creating, native)
│   ├── shipyard/            # CLI tool (commands, config, templates)
│   ├── quarry/              # Process manager (commands, config, management)
│   ├── ember/               # Logging (loggers, transports, formatters)
│   ├── lantern/             # DevTools (panels, integrations, API)
│   ├── assay/               # Testing (assertions, mocking)
│   ├── buffer/              # Binary buffer operations
│   ├── net/                 # Networking (TCP, UDP, TLS)
│   ├── fs/                  # File system operations
│   ├── archive/             # Compression (tar, gzip)
│   ├── time/                # Date/time utilities
│   ├── regex/               # Regular expressions
│   ├── redis/               # Redis client
│   ├── mqtt/                # MQTT messaging
│   ├── s3/                  # S3-compatible storage
│   ├── backend-services/    # Backend patterns
│   └── guides/              # Tutorials (REST API, web app, auth, deploy)
├── views/
│   ├── layouts/
│   │   └── base.vein        # Main layout (header, sidebar slot, footer)
│   ├── pages/
│   │   ├── home.vein        # Landing page
│   │   ├── doc.vein         # Documentation page with TOC
│   │   └── 404.vein         # Error page
│   └── partials/
│       └── sidebar.vein     # Collapsible navigation sidebar
└── public/
    ├── css/main.css         # Design tokens (Vercel/Nothing Phone inspired)
    ├── favicon.svg          # SVG favicon (copper gradient)
    └── img/
        └── og.png           # Open Graph social preview image
```

## Documentation Sections

CopperMine covers **22 sections** organized into logical groups:

**Getting Started** — Introduction, installation, quick start, project structure

**Core Runtime** — CopperMoon runtime, built-in modules, differences from standard Lua

**Frameworks** — HoneyMoon (web), Vein (templates)

**Tooling** — Shipyard (CLI), Harbor (packages), Quarry (processes)

**Data & Storage** — Freight (ORM), Redis, S3

**Libraries** — Ember (logging), Assay (testing), Lantern (devtools), Buffer, Net, Archive, Time, Regex, MQTT

**Guides** — Step-by-step tutorials for REST APIs, web apps, authentication, and deployment

## Features

- **Custom Markdown renderer** — Full HTML conversion in pure Lua (headers, code blocks, tables, lists, blockquotes, inline formatting)
- **Auto-generated heading IDs** — All headings get slugified anchors for deep linking
- **Table of contents** — Extracted from H2/H3 headings with scroll spy highlighting
- **Search API** — `/api/search?q=keyword` endpoint for live search
- **Collapsible sidebar** — Grouped sections with smooth animations
- **Dark theme** — Pure black background with copper/orange accents
- **Responsive layout** — Fixed sidebar on desktop, TOC panel on 1440px+ screens
- **SEO optimized** — Open Graph, Twitter Cards, JSON-LD structured data, sitemap, robots.txt

## Getting Started

### Prerequisites

- [CopperMoon](https://github.com/coppermoondev/coppermoon) v0.1.0+
- [Harbor](https://packages.coppermoon.dev) package manager

### Install & Run

```bash
# Clone the repository
git clone https://github.com/coppermoondev/coppermine.git
cd coppermine

# Install dependencies
harbor install

# Start the development server (port 3002)
coppermoon app.lua
```

Open [http://localhost:3002](http://localhost:3002) in your browser.

### With Shipyard (auto-reload)

```bash
shipyard dev
```

## Adding Documentation

1. Create a Markdown file in `content/<section>/<page>.md`
2. Register the page in the `docs.sections` table in `app.lua`
3. The page will be available at `/docs/<section>/<page>`

Markdown features supported:
- Headers (H1–H6) with auto-generated anchor IDs
- Fenced code blocks with language syntax classes
- Tables with headers
- Ordered and unordered lists
- Blockquotes
- Inline code, bold, italic, links

## Routes

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Landing page |
| GET | `/docs/:section` | Redirect to first page of section |
| GET | `/docs/:section/:page` | Render documentation page |
| GET | `/api/search?q=...` | Search documentation titles |
| GET | `/robots.txt` | Robots file for crawlers |
| GET | `/sitemap.xml` | XML sitemap for search engines |

## Configuration

**Environment variables:**

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `3002` | Server port |
| `NODE_ENV` | `development` | Environment mode |

## Design

- **Theme:** Dark mode inspired by Vercel and Nothing Phone
- **Colors:** Pure black (`#000`) with copper (`#c97c3c`) and orange (`#ff6b35`) accents
- **Typography:** Inter (body), JetBrains Mono (code)
- **Layout:** Fixed 260px sidebar + 720px max-width content + optional TOC panel

## License

MIT
