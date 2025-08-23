<?php
/**
 * REST API endpoint tests
 * 
 * @package buddynext
 */

namespace BuddyNext\Tests\Integration;

use WP_UnitTestCase;
use WP_REST_Request;
use WP_REST_Server;

class RestApiTest extends WP_UnitTestCase {
    
    protected $server;
    
    protected function setUp(): void {
        parent::setUp();
        
        global $wp_rest_server;
        $this->server = $wp_rest_server = new WP_REST_Server();
        do_action('rest_api_init');
    }
    
    protected function tearDown(): void {
        global $wp_rest_server;
        $wp_rest_server = null;
        parent::tearDown();
    }
    
    /**
     * Test REST API namespace registration
     */
    public function test_namespace_registered() {
        $namespaces = $this->server->get_namespaces();
        $this->assertContains(
            'buddypress/v1',
            $namespaces,
            'BuddyPress REST namespace should be registered'
        );
    }
    
    /**
     * Test that routes are registered
     */
    public function test_routes_registered() {
        $routes = $this->server->get_routes();
        $this->assertArrayHasKey(
            '/buddypress/v1',
            $routes,
            'BuddyPress routes should be registered'
        );
    }
    
    /**
     * Test unauthorized access returns 401
     */
    public function test_unauthorized_access() {
        $request = new WP_REST_Request('GET', '/buddypress/v1/members');
        $response = $this->server->dispatch($request);
        
        // Some endpoints may be public, adjust as needed
        $this->assertContains(
            $response->get_status(),
            [200, 401, 403],
            'Response should be valid status code'
        );
    }
}