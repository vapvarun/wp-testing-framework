# AI Integration Guide - WordPress Testing Framework v12.0

## Overview
The framework now features deep AI integration across all testing phases, providing intelligent analysis, automated code generation, and smart recommendations.

## AI Service Module
Located at: `bash-modules/shared/ai-service.sh`

### Core AI Functions

#### 1. Security Analysis
- `ai_detect_vulnerabilities()` - Identifies security vulnerabilities with severity ratings
- `ai_review_code()` - Performs security-focused code review
- Detects: SQL injection, XSS, CSRF, authentication bypass, privilege escalation

#### 2. Performance Optimization
- `ai_suggest_optimizations()` - Provides specific optimization recommendations
- `ai_analyze_code()` - Analyzes performance bottlenecks
- Identifies: Database query optimization, caching opportunities, memory leaks

#### 3. Code Quality
- `ai_detect_patterns()` - Identifies design patterns and anti-patterns
- `ai_check_compatibility()` - Checks PHP/WordPress version compatibility
- Reviews: Code smells, SOLID principles, WordPress standards

#### 4. Documentation Generation
- `ai_generate_documentation()` - Creates user/developer/inline documentation
- Generates: API docs, user guides, PHPDoc comments
- Formats: Markdown, structured documentation

#### 5. Test Generation
- `ai_generate_tests()` - Creates PHPUnit tests for functions
- Includes: Edge cases, error conditions, WordPress mocks
- Outputs: Complete, runnable test code

## AI Integration by Phase

### Phase 1: Setup
- Minimal AI usage (environment preparation)

### Phase 2: Detection (AI-ENHANCED ✅)
- **AI Pattern Detection**: Identifies design patterns
- **AI Architecture Analysis**: Analyzes code structure
- **AI Compatibility Check**: Version compatibility analysis

### Phase 3: AI Analysis (CORE AI PHASE)
- AST parsing with AI enhancement
- Code complexity analysis
- Pattern recognition
- AI-driven insights

### Phase 4: Security (AI-ENHANCED ✅)
- **AI Vulnerability Detection**: Deep vulnerability scanning
- **AI Security Review**: Comprehensive security analysis
- Combines traditional scanning with AI intelligence

### Phase 5: Performance (AI-ENHANCED ✅)
- **AI Optimization Suggestions**: Specific performance improvements
- **AI Performance Review**: Bottleneck identification
- Provides actionable optimization tasks

### Phase 6: Test Generation
- AI-assisted test creation
- Intelligent test case generation
- Coverage optimization

### Phase 7: Visual Testing
- AI-powered screenshot analysis (planned)
- Visual regression detection

### Phase 8: Integration
- AI-driven integration testing
- Compatibility analysis

### Phase 9: Documentation (AI-ENHANCED ✅)
- **AI User Documentation**: Automatic user guide generation
- **AI Developer Documentation**: API documentation
- **AI Inline Documentation**: PHPDoc generation

### Phase 10: Consolidation
- AI summary generation
- Insight aggregation

### Phase 11: Live Testing
- AI-powered test data generation
- Dynamic testing scenarios

### Phase 12: Safekeeping
- Minimal AI usage (archiving)

## Usage

### Enable AI Features
```bash
export ANTHROPIC_API_KEY="your-api-key"
./test-plugin.sh plugin-name
```

### Run Specific AI Analysis
```bash
# Security-focused AI analysis
./run-phase.sh -p plugin-name -n 4

# Performance AI analysis
./run-phase.sh -p plugin-name -n 5

# Documentation generation
./run-phase.sh -p plugin-name -n 9
```

### Direct AI Service Usage
```bash
source bash-modules/shared/ai-service.sh
ai_detect_vulnerabilities "/path/to/plugin" "output.json"
ai_suggest_optimizations "/path/to/plugin" "metrics.txt" "suggestions.md"
```

## AI Output Files

Each phase generates AI-specific outputs in the scan directory:

```
wp-content/uploads/wbcom-scan/[plugin]/[date]/
├── ai-vulnerabilities.json         # Security vulnerabilities
├── ai-security-review.md          # Security analysis
├── ai-performance-optimizations.md # Performance suggestions
├── ai-performance-review.md       # Performance analysis
├── ai-patterns.json               # Design patterns
├── ai-architecture.md             # Architecture analysis
├── ai-compatibility.json          # Compatibility check
├── ai-user-documentation.md      # User documentation
├── ai-developer-documentation.md  # Developer documentation
└── ai-inline-documentation.md    # Inline doc suggestions
```

## API Configuration

### Claude API (Default)
- Model: `claude-3-haiku-20240307`
- Max tokens: 4000
- Optimized for code analysis

### Adding Other AI Providers
Edit `ai-service.sh` to add support for:
- OpenAI GPT-4
- Google Gemini
- Local LLMs

## Best Practices

1. **API Key Security**
   - Never commit API keys
   - Use environment variables
   - Store in `.env` files

2. **Cost Optimization**
   - AI analysis adds ~$0.10-0.50 per plugin
   - Use selective phases for cost control
   - Cache AI results for reuse

3. **Quality Control**
   - Review AI-generated code
   - Validate security recommendations
   - Test generated documentation

## Troubleshooting

### No AI Analysis Running
```bash
# Check API key
echo $ANTHROPIC_API_KEY

# Test AI service
source bash-modules/shared/ai-service.sh
check_ai_availability && echo "AI available" || echo "AI not available"
```

### API Errors
- Check API key validity
- Verify internet connection
- Check API rate limits

## Future Enhancements

1. **Multi-model support**: GPT-4, Gemini integration
2. **AI-powered visual testing**: Screenshot analysis
3. **Predictive analysis**: Predict potential issues
4. **Auto-fixing**: AI-generated patches
5. **Learning system**: Improve based on feedback

## Summary

The framework now provides comprehensive AI integration that:
- **Enhances security** with deep vulnerability analysis
- **Optimizes performance** with specific recommendations
- **Generates documentation** automatically
- **Improves code quality** through intelligent review
- **Saves time** with automated analysis

AI is no longer just a tool but a core component driving intelligent testing and analysis throughout the framework.