<?php
/**
 * Loaded from wp-config.php via WORDPRESS_CONFIG_EXTRA (set in docker/Dockerfile).
 * No secrets here: credentials come from Kubernetes Secrets / env vars.
 */

$environment = getenv( 'WP_ENV' ) ?: 'production';

if ( ! defined( 'WP_ENVIRONMENT_TYPE' ) ) {
    define( 'WP_ENVIRONMENT_TYPE', $environment === 'production' ? 'production' : 'development' );
}

// nginx-ingress terminates TLS upstream and forwards the original scheme.
if ( isset( $_SERVER['HTTP_X_FORWARDED_PROTO'] ) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https' ) {
    $_SERVER['HTTPS'] = 'on';
}
