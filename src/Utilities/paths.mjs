/**
 * WP Testing Framework - Path Configuration (JavaScript)
 */

export const wpTestingPaths = {
    getScanDir: (plugin) => `../wp-content/uploads/wbcom-scan/${plugin}/`,
    getPlanDir: (plugin) => `../wp-content/uploads/wbcom-plan/${plugin}/`,
    getComponentScanPath: (plugin, component) => 
        `../wp-content/uploads/wbcom-scan/${plugin}/components/${component}-scan.json`,
    getApiScanPath: (plugin, type) => 
        `../wp-content/uploads/wbcom-scan/${plugin}/api/${type}-api.json`,
    getAnalysisPath: (plugin, type) => 
        `../wp-content/uploads/wbcom-scan/${plugin}/analysis/${type}-analysis.json`,
    getTemplatePath: (plugin, type) => 
        `../wp-content/uploads/wbcom-scan/${plugin}/templates/${type}-template.json`,
    getMainScanPath: (plugin) => 
        `../wp-content/uploads/wbcom-scan/${plugin}/${plugin}-complete.json`,
    
    // Plan paths
    getModelPath: (plugin, model) => 
        `../wp-content/uploads/wbcom-plan/${plugin}/models/${model}.json`,
    getTemplatePlanPath: (plugin, template) => 
        `../wp-content/uploads/wbcom-plan/${plugin}/templates/${template}.json`,
    getKnowledgePath: (plugin, topic) => 
        `../wp-content/uploads/wbcom-plan/${plugin}/knowledge/${topic}.json`
};

export default wpTestingPaths;