# HaroonNet ISP Platform - Testing Suite

This directory contains comprehensive tests for the HaroonNet ISP Platform, including unit tests, integration tests, load tests, and end-to-end tests.

## Test Structure

```
tests/
├── unit/                   # Unit tests for individual components
│   ├── api/               # API unit tests
│   ├── worker/            # Worker task unit tests
│   └── utils/             # Utility function tests
├── integration/           # Integration tests
│   ├── database/          # Database integration tests
│   ├── radius/            # RADIUS integration tests
│   └── services/          # Service integration tests
├── e2e/                   # End-to-end tests
│   ├── admin-ui/          # Admin portal E2E tests
│   ├── customer-portal/   # Customer portal E2E tests
│   └── api/               # API E2E tests
├── load/                  # Load and performance tests
│   ├── radius/            # RADIUS load tests
│   ├── api/               # API load tests
│   └── database/          # Database performance tests
├── fixtures/              # Test data and fixtures
│   ├── users.json
│   ├── customers.json
│   └── radius_data.json
├── utils/                 # Test utilities and helpers
└── config/                # Test configuration files
```

## Test Categories

### 1. Unit Tests
- API endpoint logic
- Worker task functions
- Database models
- Utility functions
- Authentication/authorization

### 2. Integration Tests
- Database operations
- RADIUS server communication
- External service integrations
- Message queue operations

### 3. End-to-End Tests
- Complete user workflows
- Admin portal functionality
- Customer portal features
- API workflows

### 4. Load Tests
- 10,000+ concurrent RADIUS sessions
- High-volume API requests
- Database performance under load
- Worker queue processing

## Running Tests

### Prerequisites
```bash
# Install test dependencies
pip install pytest pytest-asyncio pytest-mock
npm install --dev jest supertest playwright
```

### Unit Tests
```bash
# Python unit tests
pytest tests/unit/ -v

# JavaScript unit tests
npm test
```

### Integration Tests
```bash
# Run integration tests (requires running services)
pytest tests/integration/ -v
```

### End-to-End Tests
```bash
# Run E2E tests with Playwright
npx playwright test tests/e2e/
```

### Load Tests
```bash
# RADIUS load test
python tests/load/radius/test_radius_load.py

# API load test
python tests/load/api/test_api_load.py
```

### All Tests
```bash
# Run complete test suite
./scripts/run_tests.sh
```

## Test Configuration

Tests use separate configuration and databases:
- Test database: `haroonnet_test`
- Test RADIUS database: `radius_test`
- Test Redis database: `1`

## Continuous Integration

Tests are automatically run on:
- Pull requests
- Main branch commits
- Nightly builds

## Performance Benchmarks

The platform must meet these performance criteria:

### RADIUS Performance
- Authentication: < 100ms response time
- Accounting: < 50ms processing time
- CoA/DM: < 200ms response time
- Concurrent sessions: 10,000+ active

### API Performance
- Average response time: < 200ms
- 95th percentile: < 500ms
- Throughput: 1000+ requests/second
- Error rate: < 0.1%

### Database Performance
- Query response time: < 100ms
- Connection pool: 50+ concurrent connections
- Backup time: < 30 minutes
- Recovery time: < 5 minutes

## Test Data Management

Test data is managed through:
- JSON fixtures for consistent test data
- Database seeders for integration tests
- Factory functions for dynamic test data
- Cleanup scripts for test isolation

## Reporting

Test results are reported through:
- JUnit XML for CI integration
- Coverage reports (minimum 80%)
- Performance metrics
- Test execution summaries
