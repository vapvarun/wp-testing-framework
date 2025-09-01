# AI-Driven Test Data Generation

## Overview

The framework now uses AI to intelligently generate test data based on the plugin's actual database patterns, rather than generic test data. This ensures realistic testing scenarios specific to each plugin type.

## How It Works

### 1. Plugin Type Detection
The system automatically detects the plugin type by analyzing code patterns and database structures:

- **E-commerce**: Products, orders, payments, shipping methods, cart tables
- **Forum/Community**: Topics, replies, user discussions, forum hierarchies  
- **Forms**: Form submissions, field validations, entry storage
- **Membership**: Subscriptions, access levels, payment history
- **LMS**: Courses, lessons, enrollments, quiz results
- **Events**: Bookings, schedules, attendees, venue management
- **Gallery/Media**: Albums, image metadata, gallery relationships
- **Social**: Profiles, connections, activity streams, notifications
- **SEO**: Meta tags, sitemaps, redirects, schema markup
- **Security**: Login attempts, firewall rules, audit logs

### 2. Database Analysis
The phase analyzes:

#### Custom Tables
```sql
-- Detects plugin-specific tables
SHOW TABLES LIKE '%plugin_name%';
DESCRIBE custom_table;
```

#### Query Patterns
- INSERT operations (what data is saved)
- UPDATE operations (what gets modified)
- SELECT queries (what relationships exist)
- CREATE TABLE statements (schema)

#### Meta Operations
- Post meta keys and values
- User meta patterns
- Term meta usage
- Options and transients

### 3. AI Prompt Generation

Based on the analysis, the system generates a comprehensive prompt that includes:

1. **Plugin context** 
   - Detected plugin type and category
   - Core functionality patterns
   - Integration points with WordPress

2. **Database schema** 
   - Custom tables with full structure
   - Column types and constraints
   - Foreign key relationships
   - Index definitions

3. **Query patterns** 
   - INSERT operations showing data structure
   - UPDATE patterns revealing business logic
   - SELECT queries exposing relationships
   - JOIN operations showing data connections

4. **Form fields** 
   - Input field names and types
   - Validation rules and patterns
   - Required vs optional fields
   - Data sanitization methods

5. **Feature list** 
   - Custom Post Types with meta fields
   - Shortcodes with parameter analysis
   - AJAX handlers and endpoints
   - Admin pages and settings
   - Hooks and filters with context

### 4. AI Response Format

The AI generates test data in multiple formats:

#### SQL Queries
```sql
-- Direct database inserts for custom tables
INSERT INTO wp_plugin_events (title, date, venue) 
VALUES ('Test Event', '2024-12-01', 'Virtual');

-- Meta data for relationships
INSERT INTO wp_postmeta (post_id, meta_key, meta_value) 
VALUES (123, '_event_attendees', 'a:2:{i:0;i:1;i:1;i:2;}');
```

#### WP-CLI Commands
```bash
# Create test content
wp post create --post_type=event --post_title="Conference 2024"

# Set up relationships
wp term create event_category "Workshops" --slug=workshops
```

#### PHP Arrays for Complex Data
```php
// For serialized options
$settings = array(
    'enable_bookings' => true,
    'max_attendees' => 100,
    'payment_methods' => array('stripe', 'paypal')
);
update_option('event_plugin_settings', $settings);
```

## Plugin-Specific Test Scenarios

### E-commerce Plugins
- Products with variations (size, color)
- Orders in different statuses (pending, processing, completed)
- Customer accounts with order history
- Coupons and discount rules
- Inventory tracking data

### Forum Plugins  
- Forum hierarchy (categories → forums → topics → replies)
- User roles (moderator, member, guest)
- Private/hidden content
- Sticky and locked topics
- User reputation/points

### Form Plugins
- Multi-step forms
- Conditional logic
- File uploads
- Email notifications
- Spam submissions for testing filters

### Membership Plugins
- Multiple membership levels
- Subscription periods (monthly, yearly)
- Payment history
- Content restrictions
- Member directories

### LMS Plugins
- Course structure (modules → lessons → quizzes)
- Student enrollments
- Progress tracking
- Certificates and badges
- Grading systems

## Benefits of AI-Driven Approach

### 1. **Contextual Relevance**
Test data matches what the plugin actually does, not generic posts

### 2. **Relationship Integrity**
Maintains foreign keys and data relationships

### 3. **Edge Case Coverage**
Tests boundaries, special characters, large datasets

### 4. **Performance Testing**
Creates realistic data volumes for stress testing

### 5. **State Variations**
Tests different plugin states (active, trial, expired)

## Usage

### Automatic Generation
```bash
# Run Phase 6 - AI analyzes and generates prompt
./test-plugin.sh plugin-name

# Find the AI prompt at:
# wbcom-scan/plugin-name/2025-09/analysis-requests/phase-6-ai-test-data.md
```

### Manual AI Interaction
1. Copy the generated prompt
2. Paste into Claude/ChatGPT
3. Get SQL queries and commands
4. Save to `test-data/` directory
5. Execute with provided script

### Execution
```bash
# Automatic execution with WP-CLI
cd wbcom-scan/plugin-name/2025-09/test-data/
./execute-test-data.sh plugin-name /path/to/wordpress

# Or manual SQL execution
mysql -u root wordpress < test-data.sql
```

## Example: Forum Plugin Test Data

### AI Detection
```
Plugin Type: forum
Patterns: [forums, topics, replies, users]
Custom Tables: wp_bbp_forums, wp_bbp_topics, wp_bbp_replies
```

### AI Generated Test Data
```sql
-- Create forum structure
INSERT INTO wp_posts (post_type, post_title, post_status) 
VALUES ('forum', 'General Discussion', 'publish');

-- Create topic with meta
INSERT INTO wp_posts (post_type, post_title, post_parent, post_status) 
VALUES ('topic', 'Welcome to the forum!', @forum_id, 'publish');

INSERT INTO wp_postmeta (post_id, meta_key, meta_value)
VALUES (@topic_id, '_bbp_reply_count', '15'),
       (@topic_id, '_bbp_voice_count', '8'),
       (@topic_id, '_bbp_last_active_time', '2024-01-15 10:30:00');

-- Create replies
INSERT INTO wp_posts (post_type, post_content, post_parent, post_status)
VALUES ('reply', 'Great to be here!', @topic_id, 'publish');
```

## Integration with Other Phases

### Phase 6 (AI Test Data Generation)
The AI-driven test data generation is integrated as Phase 6 in the testing pipeline:
- Analyzes all database queries and custom tables
- Detects plugin type from code patterns
- Generates contextual test data based on actual plugin behavior
- Creates AI prompt with complete database schema and patterns

### Phase 7 (Visual Testing)
Uses the test data URLs and IDs for screenshots:
- Screenshots pages with generated test data
- Captures plugin UI with realistic content
- Tests visual rendering with actual data relationships

### Phase 8 (Integration Testing)  
Tests with realistic data relationships:
- Validates foreign key constraints
- Tests data flow between components
- Ensures proper data persistence

### Phase 11 (Live Testing)
Executes operations on meaningful test data:
- Tests AJAX endpoints with real data
- Validates form submissions with test content
- Ensures proper user interactions

## Best Practices

1. **Review AI Output**: Always review generated SQL before execution
2. **Test Environment**: Run in staging, not production
3. **Cleanup Script**: Create matching cleanup SQL
4. **Version Control**: Save test data with plugin version
5. **Incremental Testing**: Start with small datasets, scale up

## Future Enhancements

1. **Auto-execution**: Direct API integration with AI
2. **Data Validation**: Verify test data integrity
3. **Cleanup Automation**: Auto-remove test data
4. **Performance Benchmarks**: Measure with different data sizes
5. **Multi-site Testing**: Network-aware test data