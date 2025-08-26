#!/bin/bash

echo "🚀 Starting Laravel deployment..."

# Install Composer dependencies
echo "📦 Installing Composer dependencies..."
composer install --no-dev --optimize-autoloader --no-interaction

# Skip key generation since it will be provided by Render environment variables
echo "🔑 Using APP_KEY from environment variables..."

# Cache configuration
echo "⚡ Caching configuration..."
php artisan config:cache

# Cache routes
echo "🛣️ Caching routes..."
php artisan route:cache

# Cache views
echo "👁️ Caching views..."
php artisan view:cache

# Clear and cache events
echo "🎉 Caching events..."
php artisan event:cache

# Run database migrations
echo "🗃️ Running database migrations..."
php artisan migrate --force

# Create storage symlink if it doesn't exist
if [ ! -L public/storage ]; then
    echo "🔗 Creating storage symlink..."
    php artisan storage:link
fi

# Set proper permissions
echo "🔒 Setting permissions..."
chown -R www-data:www-data /var/www
chmod -R 755 /var/www/storage
chmod -R 755 /var/www/bootstrap/cache

echo "✅ Laravel deployment completed successfully!"
