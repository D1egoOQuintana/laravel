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
    && chown -R www-data:www-data /var/www \
    && chmod -R 755 /var/www/storage \
    && chmod -R 755 /var/www/bootstrap/cache

# Make deployment script executable
RUN chmod +x /var/www/scripts/00-laravel-deploy.sh

# Don't create .env file - let Laravel use environment variables directly
RUN rm -f /var/www/.env

# Run deployment script
RUN /var/www/scripts/00-laravel-deploy.sh

# Remove .env file to force using environment variables
RUN rm -f /var/www/.env

# Create a startup script that will run when container starts
RUN echo '#!/bin/bash' > /var/www/startup.sh \
    && echo 'echo "🔧 Container starting..."' >> /var/www/startup.sh \
    && echo 'echo "📍 Checking environment variables..."' >> /var/www/startup.sh \
    && echo 'echo "APP_KEY: ${APP_KEY:0:20}..."' >> /var/www/startup.sh \
    && echo 'echo "APP_ENV: $APP_ENV"' >> /var/www/startup.sh \
    && echo 'echo "DB_CONNECTION: $DB_CONNECTION"' >> /var/www/startup.sh \
    && echo 'echo "🚀 Starting supervisord..."' >> /var/www/startup.sh \
    && echo '/usr/bin/supervisord' >> /var/www/startup.sh \
    && chmod +x /var/www/startup.sh

# Expose port 10000 (required by Render)
EXPOSE 10000

# Start supervisor
CMD ["/var/www/startup.sh"]
