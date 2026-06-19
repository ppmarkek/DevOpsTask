<?php
/**
 * Plugin Name: DevOps Environment
 * Description: Surfaces the deployment environment so we can confirm which build is live.
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

function devops_current_environment() {
    return getenv( 'WP_ENV' ) ?: 'production';
}

add_action( 'send_headers', function () {
    header( 'X-DevOps-Env: ' . devops_current_environment() );
} );

add_filter( 'admin_footer_text', function ( $text ) {
    return $text . ' | env: ' . esc_html( devops_current_environment() );
} );
