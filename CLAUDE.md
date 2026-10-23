# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Jekyll-based static blog site for duckpond.ch - a tech blog focused on security, networking, and software development. The site is containerized using Docker and includes infrastructure for both development and production environments.

## Development Commands

### Start Development Environment
```bash
./_env/up.sh dev
```

### Start Development Environment with Drafts
```bash
./_env/up.sh dev up jekyll-dev
```

### Production Environment
```bash
./_env/up.sh --decrypt "PASSWORD" prod
```

### Build and Force Recreate
```bash
./_env/up.sh -v --decrypt PASSWORD prod up --build --force-recreate
```

### Jekyll Commands (within container)
```bash
# Build site
jekyll build

# Build with drafts
jekyll build --drafts

# Build and watch for changes
jekyll build --watch
```

## Architecture

### Directory Structure
- `_posts/` - Blog posts in Markdown format with YAML frontmatter
- `_drafts/` - Draft posts not yet published
- `_layouts/` - Jekyll layout templates (default.html, post.html, page.html)
- `_includes/` - Reusable template components (SEO, favicons, SVG icons)
- `_sass/` - SCSS stylesheets
- `static/` - Static assets (CSS, JS, images, post-specific resources)
- `_env/` - Docker infrastructure and configuration
- `category/` - Category archive pages

### Key Components
- **Jekyll Site Generator**: Static site built with Jekyll, using Kramdown for Markdown processing
- **Docker Multi-Environment**: Separate configurations for development (`docker-compose-dev.yml`) and production (`docker-compose-prod.yml`)
- **Responsive Images**: Jekyll plugin for automatic image resizing and optimization
- **Search Functionality**: Client-side search implementation with super-search.js
- **SEO Optimization**: Jekyll SEO tag plugin with custom SEO includes

### Environment Configuration
The `_env/up.sh` script orchestrates different environments:
- `dev` - Development with live reloading
- `prod` - Full production stack with mail server
- `bprod` - Blog-only production
- `mprod` - Mail server only

### Content Management
- Posts use YAML frontmatter with categories, keywords, and optional featured images
- Images stored in `static/posts/[post-name]/` directories
- Categories automatically generate archive pages
- Atom feed generation for RSS subscriptions

## Plugin Configuration
- jekyll-paginate: 20 posts per page
- jekyll-responsive-image: Automatic image optimization with multiple sizes (480px, 800px, 1400px)
- jekyll-minifier: HTML/CSS/JS compression
- jekyll-seo-tag: Meta tags and structured data
- jekyll-feed: RSS/Atom feed generation

## Infrastructure Notes
- Uses encrypted configuration files (.gpg) for sensitive data
- Mailcow integration for email services
- Nginx reverse proxy configuration
- Volume synchronization for backup/restore operations
- Base Docker image building before environment-specific services
