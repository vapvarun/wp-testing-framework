<?php
/**
 * WP Testing Framework - Path Configuration
 * 
 * Centralized path configuration for plugin-specific directories
 */

class WPTestingPaths {
    
    /**
     * Get scan directory for a plugin
     */
    public static function getScanDir($plugin) {
        $upload_dir = wp_upload_dir();
        return $upload_dir['basedir'] . '/wbcom-scan/' . $plugin . '/';
    }
    
    /**
     * Get plan directory for a plugin
     */
    public static function getPlanDir($plugin) {
        $upload_dir = wp_upload_dir();
        return $upload_dir['basedir'] . '/wbcom-plan/' . $plugin . '/';
    }
    
    /**
     * Get component scan path
     */
    public static function getComponentScanPath($plugin, $component, $timestamp = null) {
        $timestamp = $timestamp ?: date('Y-m-d-His');
        return self::getScanDir($plugin) . 'components/' . $component . '-scan-' . $timestamp . '.json';
    }
    
    /**
     * Get API scan path
     */
    public static function getApiScanPath($plugin, $type, $timestamp = null) {
        $timestamp = $timestamp ?: date('Y-m-d-His');
        return self::getScanDir($plugin) . 'api/' . $type . '-api-' . $timestamp . '.json';
    }
    
    /**
     * Get analysis path
     */
    public static function getAnalysisPath($plugin, $type, $timestamp = null) {
        $timestamp = $timestamp ?: date('Y-m-d-His');
        return self::getScanDir($plugin) . 'analysis/' . $type . '-analysis-' . $timestamp . '.json';
    }
    
    /**
     * Get template scan path
     */
    public static function getTemplateScanPath($plugin, $type, $timestamp = null) {
        $timestamp = $timestamp ?: date('Y-m-d-His');
        return self::getScanDir($plugin) . 'templates/' . $type . '-template-' . $timestamp . '.json';
    }
    
    /**
     * Ensure directory exists
     */
    public static function ensureDirectory($path) {
        $dir = is_dir($path) ? $path : dirname($path);
        if (!is_dir($dir)) {
            wp_mkdir_p($dir);
        }
        return $dir;
    }
}

// JavaScript version for Node tools
const wpTestingPaths = {
    getScanDir: (plugin) => `../wp-content/uploads/wbcom-scan/${plugin}/`,
    getPlanDir: (plugin) => `../wp-content/uploads/wbcom-plan/${plugin}/`,
    getComponentScanPath: (plugin, component) => 
        `../wp-content/uploads/wbcom-scan/${plugin}/components/${component}-scan.json`,
    getApiScanPath: (plugin, type) => 
        `../wp-content/uploads/wbcom-scan/${plugin}/api/${type}-api.json`,
    getMainScanPath: (plugin) => 
        `../wp-content/uploads/wbcom-scan/${plugin}/${plugin}-complete.json`
};

if (typeof module !== 'undefined') {
    module.exports = wpTestingPaths;
}