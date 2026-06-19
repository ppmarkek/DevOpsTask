<?php

add_action( 'after_setup_theme', function () {
    add_theme_support( 'title-tag' );
    add_theme_support( 'automatic-feed-links' );
} );

add_action( 'wp_enqueue_scripts', function () {
    wp_enqueue_style( 'devops-theme', get_stylesheet_uri(), array(), '1.0.0' );
} );
