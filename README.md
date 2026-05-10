# SpaceForEdu

A case-management web app for international students going through document homologation (equivalency recognition) in Spain. Students submit requests, upload supporting documents, and communicate with an admin who guides them through the process. Payments are handled via Stripe.

**Key features:**
- Request pipeline with statuses (draft → submitted → in review → awaiting payment → resolved)
- Secure document uploads (PDF, JPEG, PNG, WebP — up to 15 MB each)
- Real-time chat between student and admin per request
- Stripe payment integration with webhook confirmation
- In-app and web push notifications
- Role-based access: student and super-admin

## Requirements

- **Ruby** 3.4.9
- **Bundler** (`gem install bundler`)
- **Node.js** (any recent LTS version)
- **SQLite3** (usually pre-installed on macOS/Linux)

The easiest way to install Ruby is via [mise](https://mise.jdx.dev/) or [rbenv](https://github.com/rbenv/rbenv).

## Setup

```bash
# 1. Install Ruby dependencies
bundle install

# 2. Create and seed the database
bin/rails db:create db:migrate db:seed

# 3. Set up credentials (Stripe keys live here)
#    The vault is already committed; ask a teammate for the master key
#    and place it in config/master.key (not committed to git)
```

## Running locally

You need two processes running at the same time. The simplest way:

```bash
# Option A — with foreman (install once: gem install foreman)
foreman start -f Procfile.dev

# Option B — two separate terminals
bin/rails server              # terminal 1: web server on http://localhost:3000
bin/rails tailwindcss:watch   # terminal 2: CSS compiler
```

Open [http://localhost:3000](http://localhost:3000).

## Stripe webhooks (optional for local dev)

To test payments locally, forward Stripe events to your machine:

```bash
stripe listen --forward-to localhost:3000/payments/webhook
```

The webhook secret printed by this command goes into Rails credentials under `stripe.webhook_secret`.

## Running tests

```bash
bin/rails test
```
