# Deprecated Scripts

## Why These Scripts Are Deprecated

As of version 2.0, the following scripts have been deprecated and moved to this backup folder:

### 1. validate-documentation.sh
**Deprecated because:** Documentation validation is now integrated directly into `test-plugin.sh` during the generation phase.

**Old usage:**
```bash
./test-plugin.sh bbpress
./validate-documentation.sh bbpress  # No longer needed
```

**New usage:**
```bash
./test-plugin.sh bbpress  # Validation happens automatically
```

### 2. enhance-documentation.sh
**Deprecated because:** Documentation enhancement happens automatically during generation if quality score is below 70%.

**Old usage:**
```bash
./test-plugin.sh bbpress
./enhance-documentation.sh bbpress  # No longer needed
```

**New usage:**
```bash
./test-plugin.sh bbpress  # Auto-enhances if needed
```

### 3. scan-for-ai.sh
**Deprecated because:** AI scanning is now integrated into Phase 3 of `test-plugin.sh`.

**Old usage:**
```bash
./scan-for-ai.sh bbpress  # Separate AI scan
```

**New usage:**
```bash
./test-plugin.sh bbpress  # Includes AI-driven analysis in Phase 3
```

### 4. simple-test.sh
**Deprecated because:** The simple test functionality is now available as a test type in the main script.

**Old usage:**
```bash
./simple-test.sh bbpress  # Basic test only
```

**New usage:**
```bash
./test-plugin.sh bbpress quick  # Quick test mode
```

## What Replaced Them

The functionality of both scripts is now integrated into `test-plugin.sh`:

1. **Validation Function:** `validate_doc_quality()` in test-plugin.sh
   - Checks line count, code blocks, specific references
   - Calculates quality score
   - Triggers auto-enhancement if score < 70%

2. **Auto-Enhancement:** Happens inline during documentation generation
   - Adds more content from scan results
   - Includes security findings, performance metrics
   - Re-validates after enhancement

3. **Quality Report:** Generated automatically as `QUALITY-REPORT.md`
   - Shows scores for all documents
   - Confirms quality standards met
   - No manual validation needed

## Can I Still Use These Scripts?

Yes, but they're not recommended. The integrated approach ensures:
- Better quality (uses actual scan data)
- Faster execution (no duplicate processing)
- Guaranteed standards (can't skip validation)

## Migration Guide

If you have scripts or workflows using the old commands:

**Replace:**
```bash
./test-plugin.sh $PLUGIN
./validate-documentation.sh $PLUGIN
./enhance-documentation.sh $PLUGIN
```

**With:**
```bash
./test-plugin.sh $PLUGIN
# That's it! Everything is handled automatically
```

## Restoration

If you need to restore these scripts for any reason:
```bash
cp backup/deprecated-scripts/validate-documentation.sh .
cp backup/deprecated-scripts/enhance-documentation.sh .
chmod +x validate-documentation.sh enhance-documentation.sh
```

---

**Deprecated:** August 2025  
**Reason:** Functionality integrated into main script  
**Recommendation:** Use integrated validation in test-plugin.sh