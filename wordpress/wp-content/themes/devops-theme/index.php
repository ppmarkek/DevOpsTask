<?php
/**
 * Main template for the DevOps demo theme.
 */
?>
<!DOCTYPE html>
<html <?php language_attributes(); ?>>
<head>
    <meta charset="<?php bloginfo( 'charset' ); ?>">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <?php wp_head(); ?>
</head>
<body <?php body_class(); ?>>
    <h1><?php bloginfo( 'name' ); ?></h1>
    <?php
    if ( have_posts() ) {
        while ( have_posts() ) {
            the_post();
            the_title( '<h2>', '</h2>' );
            the_content();
        }
    } else {
        echo '<p>Welcome to WordPress.</p>';
    }
    wp_footer();
    ?>
</body>
</html>
