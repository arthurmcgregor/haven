# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Haven is a privacy-first, self-hosted personal blogging platform built with Ruby on Rails. It includes a built-in RSS reader, IndieWeb protocol support (IndieAuth, Micropub, Microsub), and invite-only user management. Server-rendered ERB views with plain JS for most interactivity; the post editor uses the Milkdown (ProseMirror-based) WYSIWYG library.

## Tech Stack

- Ruby 3.3.7, Rails 7.1.5.2
- PostgreSQL 13.2
- Puma 5.6.9
- Devise (auth) + OmniAuth OpenID Connect
- CommonMarker (GitHub Flavored Markdown)
- Active Storage (local disk dev, S3 production)
- Sprockets for CSS (plain `.css` stylesheets via `*= require`); jsbundling-rails + esbuild for JS
- Milkdown v7 (ProseMirror-based WYSIWYG markdown editor) on the post form, loaded as an ESM bundle from `app/javascript/editor.js`
- Yarn 4 via Corepack for JS deps

## Common Commands

```bash
# Setup
bin/setup                          # Install Ruby deps, create DB, migrate
yarn install                       # Install JS deps (requires Corepack + Yarn 4)

# Development
bin/dev                            # Rails server + esbuild watcher (Procfile.dev)
bin/rails server                   # Rails server only
yarn build                         # One-shot JS build to app/assets/builds/
yarn build --watch                 # Watch mode (if not using bin/dev)
bin/rails db:migrate               # Run migrations
bin/rails db:setup                 # Create + migrate + seed

# Tests (Minitest)
bin/rails test                     # Unit + controller + model tests
bin/rails test:system              # System tests (headless Chrome via Selenium)
bin/rails test:integration         # Integration tests
bin/rails test test/models/post_test.rb            # Single test file
bin/rails test test/models/post_test.rb:42         # Single test by line number

# Local DB via Docker
docker-compose -f docker-compose.local.yml up -d   # Start PostgreSQL only
```

## Architecture

### Authentication (3 methods)

1. **Devise** -- standard email/password sessions. `authenticate_user!` guards protected routes.
2. **OIDC** -- optional, enabled when `HAVEN_OIDC_ISSUER` env var is set. Handled by `Users::OmniauthCallbacksController`. Password login can be disabled with `HAVEN_DISABLE_PASSWORD_LOGIN=true`.
3. **IndieAuth/Bearer tokens** -- API auth for Micropub/Microsub clients. Token validation and scope checking in `ApplicationController` (`check_auth` / `check_basic_auth`). Tokens stored in `IndieAuthToken` model.

### IndieWeb Protocols

The app implements three IndieWeb specs:
- **IndieAuth** (`IndieauthController`, `lib/indie_auth_*.rb`) -- OAuth 2.0 with PKCE for IndieWeb identity. Client discovery parses remote URLs.
- **Micropub** (`MicropubController`) -- create/update/delete posts and upload media via API.
- **Microsub** (`MicrosubController`) -- manage feed subscriptions and read entries via API.

### Key Model Relationships

- `User` has_many `:posts` (as author), `:feeds`, `:indie_auth_tokens`
- `Post` belongs_to `:author` (User), has_many `:comments`, `:likes`
- `Feed` belongs_to `:user`, has_many `:feed_entries`
- Feed entries are fetched via a cron job in Docker (`lib/tasks/` rake tasks)

### Content Pipeline

Posts use CommonMarker with GFM extensions for markdown rendering. Slugs are generated from content in `PostsController.make_slug()`. Images go through Active Storage with optional resizing via `image_processing` gem.

### Post Editor

The editor is Milkdown (ProseMirror). Source at `app/javascript/editor.js`, entry for the esbuild bundle. It mounts on `<div data-milkdown>` and mirrors markdown into a hidden `#post_content` textarea, which is still the form's submitted field. Image drag/drop/paste goes through the upload plugin to `POST /uploads` (`UploadsController`), which shares logic with `PostsController` via `app/controllers/concerns/media_processing.rb`. A small "Attach Media" button handles video/audio uploads through the same endpoint.

### Custom CSS System

Users can add custom CSS (validated via Sass) and upload fonts. Served at `/css/:hash/style.css` with cache-busting hash. The `css_parser` gem is pinned to 1.21.1 due to private method usage.

## Environment Variables

### Required (production)
- `HAVEN_DB_HOST`, `HAVEN_DB_NAME`, `HAVEN_DB_ROLE`, `HAVEN_DB_PASSWORD`
- `SECRET_KEY_BASE`

### Optional
- `HAVEN_OIDC_ISSUER`, `HAVEN_OIDC_CLIENT_ID`, `HAVEN_OIDC_CLIENT_SECRET` -- enable OIDC login
- `HAVEN_DISABLE_PASSWORD_LOGIN` -- set `true` for OIDC-only auth
- `HAVEN_USER_EMAIL`, `HAVEN_USER_PASS` -- seed initial user in Docker

### Test
- `PG_USER`, `PG_PASSWORD` -- PostgreSQL credentials for test DB

## CI

GitHub Actions (`.github/workflows/tests.yml`): runs on PRs and pushes to master. PostgreSQL 13.2 service, Node 20 + Yarn (Corepack) for the JS build, ChromeDriver for system tests. Runs `yarn install && yarn build` before `bin/rails test`, `test:system`, and `test:integration`. Failed system test screenshots uploaded as artifacts.

## Deployment

Primary deployment is Docker (`Dockerfile` + `docker-compose.yml`). Also supports Heroku, AWS EC2 (`deploymentscripts/`), PikaPods, and KubeSail. Docker image published to `ghcr.io/havenweb/haven` (amd64 + arm64).
