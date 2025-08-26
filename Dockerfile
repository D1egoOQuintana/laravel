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

# Create a basic .env file for build process (will be overridden by Render env vars)
RUN echo "APP_NAME=Laravel" > /var/www/.env \
    && echo "APP_ENV=production" >> /var/www/.env \
    && echo "APP_KEY=" >> /var/www/.env \
    && echo "APP_DEBUG=true" >> /var/www/.env \
    && echo "DB_CONNECTION=pgsql" >> /var/www/.env

# Run deployment script
RUN /var/www/scripts/00-laravel-deploy.sh

# Expose port 10000 (required by Render)
EXPOSE 10000

# Start supervisor
CMD ["/usr/bin/supervisord"]
