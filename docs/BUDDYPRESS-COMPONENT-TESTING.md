# BuddyPress Component-Based Testing Strategy

## 📋 Testing Components Overview

BuddyPress has 10 major components, each requiring specific test coverage:

| Component | Priority | Test Types | Estimated Time |
|-----------|----------|------------|----------------|
| 1. Core | Critical | Unit, Integration | 2-3 hours |
| 2. Members | Critical | Unit, Integration, E2E | 3-4 hours |
| 3. Extended Profiles | High | Unit, Integration, E2E | 3-4 hours |
| 4. Activity Streams | High | Unit, Integration, E2E | 4-5 hours |
| 5. Groups | High | Unit, Integration, E2E | 4-5 hours |
| 6. Friends | Medium | Unit, Integration, E2E | 2-3 hours |
| 7. Messages | Medium | Unit, Integration, E2E | 3-4 hours |
| 8. Notifications | Medium | Unit, Integration | 2-3 hours |
| 9. Settings | Low | Unit, Integration, E2E | 2-3 hours |
| 10. Site Tracking | Low | Unit, Integration | 1-2 hours |

---

## 🧪 Component Test Suites

### 1️⃣ Core Component Tests
**Path:** `tests/phpunit/Components/Core/`

#### Test Coverage:
- [ ] Plugin activation/deactivation
- [ ] Database table creation
- [ ] Core functions initialization
- [ ] Options and settings
- [ ] Compatibility checks
- [ ] Hook registration

#### Commands:
```bash
# Run only Core component tests
./vendor/bin/phpunit --testsuite core-component

# Run with coverage
./vendor/bin/phpunit --testsuite core-component --coverage-html coverage/core
```

---

### 2️⃣ Members Component Tests
**Path:** `tests/phpunit/Components/Members/`

#### Test Coverage:
- [ ] Member registration
- [ ] Member profile display
- [ ] Member directory listing
- [ ] Member search functionality
- [ ] Avatar management
- [ ] Cover image handling
- [ ] Member type assignment
- [ ] Last activity tracking

#### Commands:
```bash
# Run only Members component tests
./vendor/bin/phpunit --testsuite members-component

# E2E tests for members
npm run test:e2e -- --grep "Members"
```

---

### 3️⃣ Extended Profiles (xProfile) Component Tests
**Path:** `tests/phpunit/Components/XProfile/`

#### Test Coverage:
- [ ] Field group creation
- [ ] Field types (text, textarea, select, checkbox, etc.)
- [ ] Field validation
- [ ] Field visibility settings
- [ ] Profile completion tracking
- [ ] Field data saving/retrieval
- [ ] Required fields enforcement

#### Commands:
```bash
# Run only xProfile component tests
./vendor/bin/phpunit --testsuite xprofile-component

# Integration tests
./vendor/bin/phpunit tests/phpunit/Components/XProfile/Integration/
```

---

### 4️⃣ Activity Streams Component Tests
**Path:** `tests/phpunit/Components/Activity/`

#### Test Coverage:
- [ ] Activity creation
- [ ] Activity types (status, posts, comments)
- [ ] Activity filtering
- [ ] @mentions functionality
- [ ] Activity favoriting
- [ ] Activity commenting
- [ ] Activity deletion
- [ ] Activity privacy
- [ ] RSS feeds
- [ ] Activity notifications

#### Commands:
```bash
# Run only Activity component tests
./vendor/bin/phpunit --testsuite activity-component

# Test activity REST API
./vendor/bin/phpunit tests/phpunit/Components/Activity/REST/
```

---

### 5️⃣ Groups Component Tests
**Path:** `tests/phpunit/Components/Groups/`

#### Test Coverage:
- [ ] Group creation/deletion
- [ ] Group types (public, private, hidden)
- [ ] Group membership management
- [ ] Group invitations
- [ ] Group requests
- [ ] Group moderator/admin roles
- [ ] Group forums integration
- [ ] Group activity streams
- [ ] Group avatar/cover images
- [ ] Group meta data

#### Commands:
```bash
# Run only Groups component tests
./vendor/bin/phpunit --testsuite groups-component

# Test group interactions
npm run test:e2e -- tests/e2e/components/groups/
```

---

### 6️⃣ Friends Component Tests
**Path:** `tests/phpunit/Components/Friends/`

#### Test Coverage:
- [ ] Friend requests
- [ ] Friend acceptance/rejection
- [ ] Friend removal
- [ ] Friendship caching
- [ ] Friend activity updates
- [ ] Friend suggestions
- [ ] Mutual friends

#### Commands:
```bash
# Run only Friends component tests
./vendor/bin/phpunit --testsuite friends-component
```

---

### 7️⃣ Messages Component Tests
**Path:** `tests/phpunit/Components/Messages/`

#### Test Coverage:
- [ ] Message composition
- [ ] Message threads
- [ ] Multiple recipients
- [ ] Message starring
- [ ] Message deletion
- [ ] Unread count tracking
- [ ] Notice messages
- [ ] Message notifications

#### Commands:
```bash
# Run only Messages component tests
./vendor/bin/phpunit --testsuite messages-component
```

---

### 8️⃣ Notifications Component Tests
**Path:** `tests/phpunit/Components/Notifications/`

#### Test Coverage:
- [ ] Notification creation
- [ ] Notification types
- [ ] Mark as read/unread
- [ ] Bulk operations
- [ ] Email notifications
- [ ] Notification settings

#### Commands:
```bash
# Run only Notifications component tests
./vendor/bin/phpunit --testsuite notifications-component
```

---

### 9️⃣ Settings Component Tests
**Path:** `tests/phpunit/Components/Settings/`

#### Test Coverage:
- [ ] Email change
- [ ] Password change
- [ ] Notification preferences
- [ ] Privacy settings
- [ ] Account deletion
- [ ] Export data

#### Commands:
```bash
# Run only Settings component tests
./vendor/bin/phpunit --testsuite settings-component
```

---

### 🔟 Site Tracking (Blogs) Component Tests
**Path:** `tests/phpunit/Components/Blogs/`

#### Test Coverage:
- [ ] New post tracking
- [ ] Comment tracking
- [ ] Blog creation (multisite)
- [ ] Blog directory
- [ ] Latest posts widget

#### Commands:
```bash
# Run only Blogs component tests
./vendor/bin/phpunit --testsuite blogs-component
```

---

## 🚀 Testing Workflow

### Phase 1: Critical Components (Week 1)
```bash
# Day 1-2: Core Component
npm run test:component core

# Day 3-4: Members Component  
npm run test:component members

# Day 5: Integration Testing
npm run test:integration
```

### Phase 2: High Priority Components (Week 2)
```bash
# Day 1-2: Extended Profiles
npm run test:component xprofile

# Day 3-4: Activity Streams
npm run test:component activity

# Day 5: Groups
npm run test:component groups
```

### Phase 3: Medium Priority Components (Week 3)
```bash
# Day 1-2: Friends & Messages
npm run test:component friends
npm run test:component messages

# Day 3: Notifications
npm run test:component notifications

# Day 4-5: Full Integration Testing
npm run test:all
```

### Phase 4: Final Components & E2E (Week 4)
```bash
# Day 1: Settings & Site Tracking
npm run test:component settings
npm run test:component blogs

# Day 2-3: End-to-End Testing
npm run test:e2e

# Day 4-5: Performance & Load Testing
npm run test:performance
```

---

## 📊 Component Test Configuration

### phpunit-components.xml
```xml
<testsuites>
    <testsuite name="core-component">
        <directory>tests/phpunit/Components/Core</directory>
    </testsuite>
    <testsuite name="members-component">
        <directory>tests/phpunit/Components/Members</directory>
    </testsuite>
    <testsuite name="xprofile-component">
        <directory>tests/phpunit/Components/XProfile</directory>
    </testsuite>
    <testsuite name="activity-component">
        <directory>tests/phpunit/Components/Activity</directory>
    </testsuite>
    <testsuite name="groups-component">
        <directory>tests/phpunit/Components/Groups</directory>
    </testsuite>
    <testsuite name="friends-component">
        <directory>tests/phpunit/Components/Friends</directory>
    </testsuite>
    <testsuite name="messages-component">
        <directory>tests/phpunit/Components/Messages</directory>
    </testsuite>
    <testsuite name="notifications-component">
        <directory>tests/phpunit/Components/Notifications</directory>
    </testsuite>
    <testsuite name="settings-component">
        <directory>tests/phpunit/Components/Settings</directory>
    </testsuite>
    <testsuite name="blogs-component">
        <directory>tests/phpunit/Components/Blogs</directory>
    </testsuite>
</testsuites>
```

---

## 🎯 Quick Test Commands

```bash
# Test single component
npm run test:bp:core
npm run test:bp:members
npm run test:bp:xprofile
npm run test:bp:activity
npm run test:bp:groups
npm run test:bp:friends
npm run test:bp:messages
npm run test:bp:notifications
npm run test:bp:settings
npm run test:bp:blogs

# Test component groups
npm run test:bp:critical    # Core + Members
npm run test:bp:social      # Friends + Messages + Activity
npm run test:bp:management  # Groups + Notifications + Settings

# Generate coverage report for component
npm run coverage:bp:members
npm run coverage:bp:activity

# Run all component tests
npm run test:bp:all
```

---

## 📈 Component Testing Progress

| Component | Unit Tests | Integration | E2E | Coverage | Status |
|-----------|------------|-------------|-----|----------|--------|
| Core | 0/15 | 0/10 | N/A | 0% | 🔴 Not Started |
| Members | 0/25 | 0/15 | 0/10 | 0% | 🔴 Not Started |
| xProfile | 0/20 | 0/12 | 0/8 | 0% | 🔴 Not Started |
| Activity | 0/30 | 0/20 | 0/15 | 0% | 🔴 Not Started |
| Groups | 0/35 | 0/25 | 0/20 | 0% | 🔴 Not Started |
| Friends | 0/15 | 0/10 | 0/5 | 0% | 🔴 Not Started |
| Messages | 0/20 | 0/15 | 0/10 | 0% | 🔴 Not Started |
| Notifications | 0/15 | 0/10 | 0/5 | 0% | 🔴 Not Started |
| Settings | 0/10 | 0/8 | 0/5 | 0% | 🔴 Not Started |
| Blogs | 0/10 | 0/8 | N/A | 0% | 🔴 Not Started |

**Total Progress:** 0/195 Unit | 0/133 Integration | 0/78 E2E

---

## 🔧 Component Test Generator

Use the component-specific test generator:

```bash
# Generate tests for specific component
node tools/generate-component-tests.js --component members
node tools/generate-component-tests.js --component activity
node tools/generate-component-tests.js --component groups

# Generate tests for all components
node tools/generate-component-tests.js --all

# Generate only specific test type
node tools/generate-component-tests.js --component members --type unit
node tools/generate-component-tests.js --component activity --type e2e
```

---

## 📝 Notes

1. **Test Isolation:** Each component's tests should be completely independent
2. **Database:** Use separate test tables or transactions for each component
3. **Fixtures:** Create component-specific fixtures in `tests/fixtures/components/`
4. **Mocking:** Mock other components when testing a specific component
5. **Performance:** Run component tests in parallel when possible
6. **CI/CD:** Set up GitHub Actions to run component tests on PR

---

Last Updated: 2025-08-23