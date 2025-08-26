# Use PHP 8.2 with FPM
FROM php:8.2-fpm

# Set working directory
WORKDIR /var/www

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libpq-dev \
    zip \
    unzip \
    nginx \
    supervisor \
    postgresql-client \
    && docker-php-ext-install pdo_pgsql pgsql mbstring exif pcntl bcmath gd zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy existing application directory contents
COPY . /var/www

# Copy existing application directory permissions
COPY --chown=www-data:www-data . /var/www

# Copy nginx configuration
COPY conf/nginx/default.conf /etc/nginx/sites-available/default

# Copy supervisor configuration
RUN echo '[supervisord]\nnodaemon=true\n\n[program:nginx]\ncommand=nginx -g "daemon off;"\nautorestart=true\n\n[program:php-fpm]\ncommand=php-fpm\nautorestart=true' > /etc/supervisor/conf.d/supervisord.conf

# Create required directories and set permissions
RUN mkdir -p /var/www/storage/logs \
    && mkdir -p /var/www/storage/framework/cache \
    && mkdir -p /var/www/storage/framework/sessions \
    && mkdir -p /var/www/storage/framework/views \
    && mkdir -p /var/www/bootstrap/cache \
    && touch /var/www/storage/logs/laravel.log \
    && chown -R www-data:www-data /var/www \
    && chmod -R 775 /var/www/storage \
    && chmod -R 775 /var/www/bootstrap/cache

# Install dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Clear any existing cache and config
RUN php artisan config:clear || true
RUN php artisan cache:clear || true
RUN php artisan view:clear || true

# Create storage symlink
RUN php artisan storage:link || true

# Create a startup script to set proper permissions at runtime
RUN echo '#!/bin/bash' > /var/www/start.sh \
    && echo 'echo "🚀 Starting Laravel application..."' >> /var/www/start.sh \
    && echo 'chown -R www-data:www-data /var/www/storage' >> /var/www/start.sh \
    && echo 'chmod -R 775 /var/www/storage' >> /var/www/start.sh \
    && echo 'echo "🗃️ Running database migrations..."' >> /var/www/start.sh \
    && echo 'php artisan migrate --force || echo "Migration failed, continuing..."' >> /var/www/start.sh \
    && echo 'echo "⚡ Caching configuration..."' >> /var/www/start.sh \
    && echo 'php artisan config:cache || true' >> /var/www/start.sh \
    && echo 'php artisan route:cache || true' >> /var/www/start.sh \
    && echo 'echo "✅ Starting web server..."' >> /var/www/start.sh \
    && echo 'exec /usr/bin/supervisord' >> /var/www/start.sh \
    && chmod +x /var/www/start.sh

# Expose port 10000 (required by Render)
EXPOSE 10000

# Start supervisor
CMD ["/var/www/start.sh"]
