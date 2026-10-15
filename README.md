# WordPress (Bedrock) Example Application on Clever Cloud

[![Clever Cloud - PaaS](https://img.shields.io/badge/Clever%20Cloud-PaaS-orange)](https://clever-cloud.com)

This is a WordPress application using [Bedrock](https://roots.io/bedrock/) ([GitHub](https://github.com/roots/bedrock)), a modern WordPress stack that keeps your installation clean from runtime code changes. It is pre-configured to deploy on [Clever Cloud](https://www.clever-cloud.com/) with MySQL and Cellar S3 storage.

## About the Application

This project is based on Bedrock 1.31.6 with the following Clever Cloud-specific modifications:

- `config/application.php` – maps Clever Cloud's `MYSQL_ADDON_*` and `CELLAR_ADDON_*` environment variables
- `composer.json` – includes `humanmade/s3-uploads` for S3 media storage and `wp-plugin/mailgun` for email delivery
- `web/app/mu-plugins/s3-uploads-filter.php` – configures a Cellar endpoint instead of AWS
- `web/.htaccess` – included and tracked (Bedrock gitignores it by default)
- `clevercloud/php.json` – sets the webroot to `/web` (PHP runtime only; on FrankenPHP, see [Deploying on FrankenPHP](#deploying-on-frankenphp))
- `setup-cellar.sh` – creates the S3 bucket on Cellar (used as a post-build hook)

## Technology Stack

- [WordPress](https://wordpress.org/) 7.1 – Content management system
- [Bedrock](https://roots.io/bedrock/) 1.31 – Modern WordPress boilerplate
- [Composer](https://getcomposer.org/) – Dependency manager for PHP
- [Cellar](https://www.clever-cloud.com/product/cellar-s3/) – S3-compatible object storage for media files

## Prerequisites

- PHP 8.3+
- Composer
- A Clever Cloud account

## Running the Application Locally

```bash
# Install dependencies
composer install

# Copy and edit the environment file
cp .env.example .env

# Start the local server
wp server
```

The application will be accessible at http://localhost:8080.

## Deploying on Clever Cloud

You have two options to deploy your WordPress application on Clever Cloud: using the Web Console or using the Clever Tools CLI.

### Option 1: Deploy using the Web Console

#### 1. Create an account on Clever Cloud

If you don't already have an account, go to the [Clever Cloud console](https://console.clever-cloud.com/) and follow the registration instructions.

#### 2. Set up your application on Clever Cloud

1. Log in to the [Clever Cloud console](https://console.clever-cloud.com/)
2. Click on "Create" and select "An application"
3. Select this project (or a fork of it) as the source
4. Choose "PHP" as the runtime environment
5. Configure your application settings (name, region, etc.)

#### 3. Add a MySQL Database Add-on

1. In your application settings, go to "Service dependencies"
2. Add a **MySQL** add-on and link it to your application

The `MYSQL_ADDON_*` environment variables will be automatically injected.

#### 4. Configure Environment Variables

Add the following environment variables in the Clever Cloud console (expert mode):

| Variable | Value | Description |
|----------|-------|-------------|
| `WP_ENV` | `production` | WordPress environment |
| `WP_HOME` | `https://your-domain.tld` | Your site URL |
| `WP_SITEURL` | `https://your-domain.tld/wp` | WordPress core URL |
| `AUTH_KEY` | *(generated)* | Authentication salts – generate all 8 keys at https://cdn.roots.io/salts.html |
| `SECURE_AUTH_KEY` | *(generated)* | |
| `LOGGED_IN_KEY` | *(generated)* | |
| `NONCE_KEY` | *(generated)* | |
| `AUTH_SALT` | *(generated)* | |
| `SECURE_AUTH_SALT` | *(generated)* | |
| `LOGGED_IN_SALT` | *(generated)* | |
| `NONCE_SALT` | *(generated)* | |

#### 5. Set up Cellar S3 Storage (for media files)

1. Create a **Cellar S3 storage** add-on and link it to your application
2. In the Cellar add-on dashboard, click on **"Create a bucket"** and give it a name
3. Add the environment variable `CELLAR_ADDON_BUCKET` with the name of your bucket
4. Restart your application to apply changes

#### 6. Deploy Your Application

You can deploy your application using Git:

```bash
# Add Clever Cloud as a remote repository
git remote add clever git+ssh://git@push-par-clevercloud-customers.services.clever-cloud.com/app_<your-app-id>.git

# Push your code to deploy
git push clever master
```

#### 7. Finish WordPress Installation

1. Set up your domain name as configured for `WP_HOME` (or use `*.cleverapps.io` for testing)
2. Access the WordPress installation page at your domain
3. After installation, go to the plugins page and activate **S3 Uploads**

### Option 2: Deploy using Clever Tools CLI

#### 1. Install Clever Tools

Install the Clever Tools CLI following the [official documentation](https://www.clever-cloud.com/doc/clever-tools/getting_started/):

```bash
# Using npm
npm install -g clever-tools

# Or using Homebrew (macOS)
brew install clever-tools
```

#### 2. Log in to your Clever Cloud account

```bash
clever login
```

#### 3. Create and configure the application

```bash
# Create a PHP application
clever create --type php <YOUR_APP_NAME>

# Add a MySQL add-on
clever addon create mysql-addon <YOUR_ADDON_NAME> --link <YOUR_APP_NAME>

# Add a Cellar S3 add-on
clever addon create cellar-addon <YOUR_CELLAR_NAME> --link <YOUR_APP_NAME>

# Add your domain (optional)
clever domain add <YOUR_DOMAIN_NAME>

# Set required environment variables
clever env set WP_ENV production
clever env set WP_HOME "https://$(clever domain | tr -d ' ')"
clever env set WP_SITEURL "https://$(clever domain | tr -d ' ')wp"



# Please remember S3 bucket names are unique
# To avoid conflicts, simply use your app id as bucket name
clever env set CELLAR_ADDON_BUCKET $(clever applications -j | jq -r '.[0].app_id' | tr '_' '-')

# Load env variables
eval "$(clever env -F shell)"

# Create the Cellar bucket on first deploy
./setup-cellar.sh

# Set authentication salts (generate at https://cdn.roots.io/salts.html)
clever env set AUTH_KEY "your-generated-key"
clever env set SECURE_AUTH_KEY "your-generated-key"
clever env set LOGGED_IN_KEY "your-generated-key"
clever env set NONCE_KEY "your-generated-key"
clever env set AUTH_SALT "your-generated-salt"
clever env set SECURE_AUTH_SALT "your-generated-salt"
clever env set LOGGED_IN_SALT "your-generated-salt"
clever env set NONCE_SALT "your-generated-salt"

```

#### 4. Deploy your application

```bash
clever deploy
```

#### 5. Open your application in a browser

Once deployed, access your site at `https://<YOUR_DOMAIN_NAME>/` and complete the WordPress installation.

## Deploying on FrankenPHP

This example also runs on Clever Cloud's [FrankenPHP runtime](https://www.clever-cloud.com/developers/doc/deploy/applications/frankenphp/), a PHP server built on Caddy. The steps are the same as above, with two differences:

1. **Choose FrankenPHP as the runtime** instead of PHP, in the console or with the CLI:

   ```bash
   clever create --type frankenphp <YOUR_APP_NAME>
   ```

2. **Set the webroot with an environment variable.** FrankenPHP ignores `clevercloud/php.json`, so you must set `CC_WEBROOT` yourself:

   ```bash
   clever env set CC_WEBROOT /web
   ```

   Without it, FrankenPHP serves the project root and every page fails with an error like `Failed opening required '.../wp/wp-admin/install.php'`, because WordPress lives in `web/wp/`.

You don't need to translate `web/.htaccess` into a Caddyfile: FrankenPHP already sends requests for anything that isn't an existing file or directory to `index.php`, which is all the WordPress rewrite rules do. If you want a custom Caddyfile later, load it with `CC_RUN_COMMAND="frankenphp run --config /path/to/Caddyfile"`.

## Sending Emails

By default, this WordPress installation cannot send emails. You can either:

- Follow [Clever Cloud's SMTP documentation](https://www.clever-cloud.com/doc/php/php-apps/#sending-emails) to configure your SMTP server
- Activate and configure the **Mailgun** plugin (installed by default)

## Installing Themes and Plugins

Themes and plugins are managed via Composer and [WP Packages](https://wp-packages.org), the repository upstream Bedrock uses. To install a new plugin or theme, add it to `composer.json` and commit:

```bash
composer require wp-plugin/plugin-name
git add composer.json composer.lock
git commit -m "Add plugin-name"
git push clever master
```

> **Note:** Pay attention to how you define your [dependencies with Composer](https://getcomposer.org/doc/01-basic-usage.md#installing-dependencies). The stricter way is to locally run `composer update` and commit your `composer.lock` file.

## Keeping WordPress Updated

WordPress updates are handled through Composer. Bedrock disables WordPress automatic updates, so security releases only reach your site when you bump the pinned `roots/wordpress` version yourself. Update the version in `composer.json`, run `composer update`, commit, and deploy. If a database migration is needed, WordPress will prompt you when logged in as administrator.

## Monitoring Your Application

Once deployed, you can monitor your application through:

- **Web Console**: The Clever Cloud console provides logs, metrics, and other tools to help you manage your application.
- **CLI**: Use `clever logs` to view application logs and `clever status` to check the status of your application.

## Differences with Bedrock

This project is based on [Bedrock 1.31.6](https://github.com/roots/bedrock/releases/tag/1.31.6) with the following changes:

- `config/application.php` uses Clever Cloud's `MYSQL_ADDON_*` variables for database configuration and `CELLAR_ADDON_*` variables for S3 storage
- `composer.json` includes `humanmade/s3-uploads` and `wp-plugin/mailgun` as additional dependencies
- `web/app/mu-plugins/s3-uploads-filter.php` configures the S3 client to use a Cellar endpoint
- `web/.htaccess` is tracked in the repository (Bedrock gitignores it by default)
- `clevercloud/php.json` configures the webroot for Clever Cloud's build system
- `setup-cellar.sh` creates the S3 bucket on Cellar via `s3cmd` (can be used as `CC_POST_BUILD_HOOK`)

## Additional Resources

- [Bedrock Documentation](https://roots.io/bedrock/docs/)
- [WordPress Documentation](https://developer.wordpress.org/)
- [Composer Documentation](https://getcomposer.org/doc/)
- [Clever Cloud PHP Documentation](https://www.clever-cloud.com/developers/doc/applications/php/)
- [Clever Cloud FrankenPHP Documentation](https://www.clever-cloud.com/developers/doc/deploy/applications/frankenphp/)
- [Clever Cloud Cellar Documentation](https://www.clever-cloud.com/developers/doc/addons/cellar/)
