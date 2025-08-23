<?php
/**
 * BuddyPress Demo Data Generator
 * Creates realistic test data for comprehensive testing
 * 
 * Usage: wp eval-file tools/bp-demo-data-generator.php
 */

class BP_Demo_Data_Generator {
    
    private $users = [];
    private $groups = [];
    private $activities = [];
    private $messages = [];
    
    private $config = [
        'users' => 50,
        'groups' => 10,
        'activities' => 200,
        'friendships' => 100,
        'messages' => 50,
        'notifications' => 100,
    ];
    
    /**
     * Generate all demo data
     */
    public function generate_all() {
        echo "🚀 Starting BuddyPress Demo Data Generation...\n";
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
        
        $this->create_users();
        $this->create_xprofile_data();
        $this->create_friendships();
        $this->create_groups();
        $this->create_activities();
        $this->create_messages();
        $this->create_notifications();
        
        echo "\n✅ Demo data generation complete!\n";
        $this->show_summary();
    }
    
    /**
     * Create demo users
     */
    private function create_users() {
        echo "👥 Creating users... ";
        
        $first_names = ['John', 'Jane', 'Mike', 'Sarah', 'David', 'Emma', 'Tom', 'Lisa', 'Chris', 'Amy'];
        $last_names = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez'];
        $interests = ['Photography', 'Music', 'Travel', 'Cooking', 'Sports', 'Reading', 'Gaming', 'Art', 'Fitness', 'Technology'];
        
        for ($i = 1; $i <= $this->config['users']; $i++) {
            $first = $first_names[array_rand($first_names)];
            $last = $last_names[array_rand($last_names)];
            $username = strtolower($first . $last . $i);
            
            $user_id = wp_create_user(
                $username,
                'password123',
                $username . '@test.com'
            );
            
            if (!is_wp_error($user_id)) {
                $this->users[] = $user_id;
                
                // Update user meta
                update_user_meta($user_id, 'first_name', $first);
                update_user_meta($user_id, 'last_name', $last);
                
                // Set last activity
                bp_update_user_last_activity($user_id);
                
                // Add some variety in user roles
                if ($i % 10 == 0) {
                    $user = new WP_User($user_id);
                    $user->set_role('editor');
                } elseif ($i % 20 == 0) {
                    $user = new WP_User($user_id);
                    $user->set_role('author');
                }
            }
        }
        
        echo "Created " . count($this->users) . " users\n";
    }
    
    /**
     * Create xProfile data
     */
    private function create_xprofile_data() {
        echo "📝 Creating xProfile data... ";
        
        if (!bp_is_active('xprofile')) {
            echo "xProfile component not active\n";
            return;
        }
        
        $bio_samples = [
            'Love traveling and meeting new people!',
            'Photography enthusiast and coffee addict.',
            'Always looking for the next adventure.',
            'Tech geek, gamer, and proud of it!',
            'Fitness is my passion, health is my wealth.',
            'Books, music, and good vibes only.',
            'Foodie exploring culinary delights.',
            'Nature lover and environmental advocate.',
            'Creative soul with a passion for art.',
            'Sports fan and weekend warrior.'
        ];
        
        $locations = ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix', 'Philadelphia', 'San Antonio', 'San Diego', 'Dallas', 'San Jose'];
        
        $count = 0;
        foreach ($this->users as $user_id) {
            // Bio field (usually field ID 2)
            xprofile_set_field_data(2, $user_id, $bio_samples[array_rand($bio_samples)]);
            
            // Location field (if exists)
            xprofile_set_field_data('Location', $user_id, $locations[array_rand($locations)]);
            
            // Interests (if exists)
            xprofile_set_field_data('Interests', $user_id, 'Music, Travel, Photography');
            
            $count++;
        }
        
        echo "Updated $count user profiles\n";
    }
    
    /**
     * Create friendships
     */
    private function create_friendships() {
        echo "🤝 Creating friendships... ";
        
        if (!bp_is_active('friends')) {
            echo "Friends component not active\n";
            return;
        }
        
        $count = 0;
        $total_users = count($this->users);
        
        for ($i = 0; $i < $this->config['friendships']; $i++) {
            $user1 = $this->users[rand(0, $total_users - 1)];
            $user2 = $this->users[rand(0, $total_users - 1)];
            
            if ($user1 != $user2 && !friends_check_friendship($user1, $user2)) {
                // Create friendship request
                friends_add_friend($user1, $user2, false);
                
                // Auto-accept 80% of friendships
                if (rand(1, 10) <= 8) {
                    $friendship_id = friends_get_friendship_id($user1, $user2);
                    friends_accept_friendship($friendship_id);
                    $count++;
                }
            }
        }
        
        echo "Created $count friendships\n";
    }
    
    /**
     * Create groups
     */
    private function create_groups() {
        echo "👥 Creating groups... ";
        
        if (!bp_is_active('groups')) {
            echo "Groups component not active\n";
            return;
        }
        
        $group_names = [
            'Photography Club' => 'Share your best shots and get feedback',
            'Book Lovers' => 'Discuss your favorite books and authors',
            'Fitness Warriors' => 'Stay motivated and share workout tips',
            'Tech Innovators' => 'Discuss latest tech trends and gadgets',
            'Travel Enthusiasts' => 'Share travel stories and destinations',
            'Foodies United' => 'Share recipes and restaurant recommendations',
            'Music Makers' => 'Connect with fellow musicians',
            'Movie Buffs' => 'Discuss latest movies and classics',
            'Entrepreneurs' => 'Network and share business ideas',
            'Gamers Guild' => 'Find gaming buddies and discuss games'
        ];
        
        $count = 0;
        foreach ($group_names as $name => $desc) {
            if ($count >= $this->config['groups']) break;
            
            $creator_id = $this->users[array_rand($this->users)];
            
            $group_id = groups_create_group([
                'creator_id' => $creator_id,
                'name' => $name,
                'description' => $desc,
                'slug' => sanitize_title($name),
                'status' => rand(1, 3) == 1 ? 'private' : 'public',
                'enable_forum' => 0,
                'date_created' => date('Y-m-d H:i:s', strtotime('-' . rand(1, 30) . ' days'))
            ]);
            
            if ($group_id) {
                $this->groups[] = $group_id;
                
                // Add random members
                $member_count = rand(5, 20);
                for ($i = 0; $i < $member_count; $i++) {
                    $user_id = $this->users[array_rand($this->users)];
                    groups_join_group($group_id, $user_id);
                }
                
                $count++;
            }
        }
        
        echo "Created $count groups\n";
    }
    
    /**
     * Create activities
     */
    private function create_activities() {
        echo "📢 Creating activities... ";
        
        if (!bp_is_active('activity')) {
            echo "Activity component not active\n";
            return;
        }
        
        $activity_content = [
            'Just joined this amazing community! 👋',
            'Anyone up for a weekend meetup?',
            'Check out this awesome photo I took today!',
            'Great discussion in the book club yesterday.',
            'Who else is excited about the upcoming event?',
            'New blog post: 10 Tips for Better Photography',
            'Morning workout complete! 💪 Feeling energized!',
            'Just finished reading an amazing book. Highly recommend!',
            'Coffee and coding - perfect Saturday morning ☕',
            'Beautiful sunset today! Nature never disappoints.',
            'Looking for recommendations for my next travel destination.',
            'Proud of hitting my fitness goals this month!',
            'Movie night suggestions anyone? 🎬',
            'Great networking event last night. Met amazing people!',
            'New recipe tried and tested. Delicious! 🍝'
        ];
        
        $count = 0;
        for ($i = 0; $i < $this->config['activities']; $i++) {
            $user_id = $this->users[array_rand($this->users)];
            $content = $activity_content[array_rand($activity_content)];
            
            // Vary activity types
            $type = 'activity_update';
            $component = 'activity';
            $item_id = 0;
            
            // 20% chance of group activity
            if (rand(1, 5) == 1 && !empty($this->groups)) {
                $component = 'groups';
                $item_id = $this->groups[array_rand($this->groups)];
            }
            
            $activity_id = bp_activity_add([
                'user_id' => $user_id,
                'component' => $component,
                'type' => $type,
                'item_id' => $item_id,
                'content' => $content,
                'recorded_time' => date('Y-m-d H:i:s', strtotime('-' . rand(1, 720) . ' hours'))
            ]);
            
            if ($activity_id) {
                $this->activities[] = $activity_id;
                
                // Add some comments (30% chance)
                if (rand(1, 10) <= 3) {
                    $this->add_activity_comments($activity_id);
                }
                
                // Add favorites (20% chance)
                if (rand(1, 5) == 1) {
                    $fav_user = $this->users[array_rand($this->users)];
                    bp_activity_add_user_favorite($activity_id, $fav_user);
                }
                
                $count++;
            }
        }
        
        echo "Created $count activities\n";
    }
    
    /**
     * Add comments to activity
     */
    private function add_activity_comments($activity_id) {
        $comments = [
            'Great post! 👍',
            'Totally agree with this!',
            'Thanks for sharing!',
            'Awesome! Count me in!',
            'This is so inspiring!',
            'Love this! ❤️',
            'Could not agree more.',
            'Well said!'
        ];
        
        $num_comments = rand(1, 5);
        for ($i = 0; $i < $num_comments; $i++) {
            $user_id = $this->users[array_rand($this->users)];
            $content = $comments[array_rand($comments)];
            
            bp_activity_new_comment([
                'activity_id' => $activity_id,
                'user_id' => $user_id,
                'content' => $content,
                'parent_id' => $activity_id
            ]);
        }
    }
    
    /**
     * Create private messages
     */
    private function create_messages() {
        echo "✉️ Creating messages... ";
        
        if (!bp_is_active('messages')) {
            echo "Messages component not active\n";
            return;
        }
        
        $subjects = [
            'Quick question',
            'About the event',
            'Great meeting you!',
            'Following up',
            'Invitation',
            'Need your advice',
            'Thank you!',
            'Collaboration opportunity'
        ];
        
        $contents = [
            'Hey! Hope you are doing well. Just wanted to reach out and say hi!',
            'It was great meeting you at the event. Would love to connect!',
            'Thanks for your help earlier. Really appreciate it!',
            'Are you coming to the meetup this weekend?',
            'I saw your post about photography. Would love to learn more!',
            'Can you recommend any good books on this topic?',
            'Let me know if you need any help with the project.',
            'Would you be interested in collaborating on this?'
        ];
        
        $count = 0;
        for ($i = 0; $i < $this->config['messages']; $i++) {
            $sender = $this->users[array_rand($this->users)];
            $recipient = $this->users[array_rand($this->users)];
            
            if ($sender != $recipient) {
                $args = [
                    'sender_id' => $sender,
                    'recipients' => [$recipient],
                    'subject' => $subjects[array_rand($subjects)],
                    'content' => $contents[array_rand($contents)],
                    'date_sent' => date('Y-m-d H:i:s', strtotime('-' . rand(1, 168) . ' hours'))
                ];
                
                if (messages_new_message($args)) {
                    $count++;
                }
            }
        }
        
        echo "Created $count message threads\n";
    }
    
    /**
     * Create notifications
     */
    private function create_notifications() {
        echo "🔔 Creating notifications... ";
        
        if (!bp_is_active('notifications')) {
            echo "Notifications component not active\n";
            return;
        }
        
        $count = 0;
        
        // Friend request notifications
        foreach ($this->users as $user_id) {
            if (rand(1, 3) == 1) { // 33% chance
                $from_user = $this->users[array_rand($this->users)];
                if ($from_user != $user_id) {
                    bp_notifications_add_notification([
                        'user_id' => $user_id,
                        'item_id' => $from_user,
                        'secondary_item_id' => 0,
                        'component_name' => 'friends',
                        'component_action' => 'friendship_request',
                        'date_notified' => bp_core_current_time(),
                        'is_new' => 1
                    ]);
                    $count++;
                }
            }
        }
        
        // Activity mention notifications
        if (!empty($this->activities)) {
            foreach ($this->activities as $activity_id) {
                if (rand(1, 5) == 1) { // 20% chance
                    $user_id = $this->users[array_rand($this->users)];
                    bp_notifications_add_notification([
                        'user_id' => $user_id,
                        'item_id' => $activity_id,
                        'secondary_item_id' => 0,
                        'component_name' => 'activity',
                        'component_action' => 'new_at_mention',
                        'date_notified' => bp_core_current_time(),
                        'is_new' => 1
                    ]);
                    $count++;
                }
            }
        }
        
        echo "Created $count notifications\n";
    }
    
    /**
     * Show summary
     */
    private function show_summary() {
        echo "\n📊 Demo Data Summary:\n";
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
        echo "Users:         " . count($this->users) . "\n";
        echo "Groups:        " . count($this->groups) . "\n";
        echo "Activities:    " . count($this->activities) . "\n";
        echo "Messages:      " . $this->config['messages'] . " threads\n";
        echo "Friendships:   " . $this->config['friendships'] . " connections\n";
        echo "Notifications: " . $this->config['notifications'] . "+\n";
        echo "\n";
        echo "Test users created with password: password123\n";
        echo "Usernames format: firstnamelastname[number]@test.com\n";
    }
    
    /**
     * Clean up all demo data
     */
    public function cleanup() {
        echo "🧹 Cleaning up demo data...\n";
        
        // Delete users
        foreach ($this->users as $user_id) {
            if (email_exists('user' . $user_id . '@test.com')) {
                wp_delete_user($user_id);
            }
        }
        
        // Clean up any orphaned data
        global $wpdb;
        $wpdb->query("DELETE FROM {$wpdb->prefix}bp_activity WHERE user_id NOT IN (SELECT ID FROM {$wpdb->users})");
        $wpdb->query("DELETE FROM {$wpdb->prefix}bp_groups WHERE creator_id NOT IN (SELECT ID FROM {$wpdb->users})");
        
        echo "✅ Demo data cleaned up\n";
    }
}

// Run the generator
$generator = new BP_Demo_Data_Generator();

// Check for command line arguments
if (isset($argv[1])) {
    switch($argv[1]) {
        case 'cleanup':
            $generator->cleanup();
            break;
        case 'generate':
        default:
            $generator->generate_all();
            break;
    }
} else {
    $generator->generate_all();
}