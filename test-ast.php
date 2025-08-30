<?php
// Test file with hooks
add_action('init', 'my_function');
add_filter('the_content', 'filter_content');
do_action('custom_hook');
