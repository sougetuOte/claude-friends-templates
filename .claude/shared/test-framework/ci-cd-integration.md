# CI/CD Integration Guidelines

## Overview

This guide provides ready-to-use configurations for integrating the test framework with popular CI/CD platforms.

## GitHub Actions

### Basic Test Pipeline

```yaml
# .github/workflows/test.yml
name: Test Suite

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  unit-tests:
    name: Unit Tests
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [16.x, 18.x, 20.x]
        python-version: [3.8, 3.9, 3.10]

    steps:
    - uses: actions/checkout@v3

    - name: Set up Node.js ${{ matrix.node-version }}
      uses: actions/setup-node@v3
      with:
        node-version: ${{ matrix.node-version }}
        cache: 'npm'

    - name: Set up Python ${{ matrix.python-version }}
      uses: actions/setup-python@v4
      with:
        python-version: ${{ matrix.python-version }}
        cache: 'pip'

    - name: Install dependencies
      run: |
        npm ci
        pip install -r requirements.txt

    - name: Run unit tests
      run: |
        npm run test:unit
        python -m pytest tests/unit/

    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage/lcov.info
        flags: unittests
        name: codecov-umbrella

  integration-tests:
    name: Integration Tests
    runs-on: ubuntu-latest
    needs: unit-tests

    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379

    steps:
    - uses: actions/checkout@v3

    - name: Set up test environment
      run: |
        cp .env.test .env
        docker-compose up -d

    - name: Run integration tests
      env:
        DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test_db
        REDIS_URL: redis://localhost:6379
      run: |
        npm run test:integration
        python -m pytest tests/integration/

  e2e-tests:
    name: E2E Tests
    runs-on: ubuntu-latest
    needs: integration-tests

    steps:
    - uses: actions/checkout@v3

    - name: Set up Node.js
      uses: actions/setup-node@v3
      with:
        node-version: 18.x

    - name: Install Playwright
      run: |
        npm ci
        npx playwright install --with-deps

    - name: Run E2E tests
      run: npm run test:e2e

    - name: Upload test artifacts
      if: failure()
      uses: actions/upload-artifact@v3
      with:
        name: playwright-traces
        path: test-results/
```

### Advanced Features

```yaml
# Advanced GitHub Actions configuration
name: Advanced Test Pipeline

on:
  schedule:
    - cron: '0 2 * * *'  # Nightly tests
  workflow_dispatch:      # Manual trigger

jobs:
  test-matrix:
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        test-suite: [unit, integration, e2e]
        include:
          - os: ubuntu-latest
            test-suite: performance

    runs-on: ${{ matrix.os }}

    steps:
    - uses: actions/checkout@v3

    - name: Cache dependencies
      uses: actions/cache@v3
      with:
        path: |
          ~/.npm
          ~/.cache/pip
          ~/.cache/playwright
        key: ${{ runner.os }}-deps-${{ hashFiles('**/package-lock.json', '**/requirements.txt') }}

    - name: Run ${{ matrix.test-suite }} tests
      run: |
        npm run test:${{ matrix.test-suite }}

    - name: Performance metrics
      if: matrix.test-suite == 'performance'
      uses: benchmark-action/github-action-benchmark@v1
      with:
        tool: 'customBiggerIsBetter'
        output-file-path: output/performance.json
        github-token: ${{ secrets.GITHUB_TOKEN }}
        auto-push: true
```

## GitLab CI

### Basic Configuration

```yaml
# .gitlab-ci.yml
stages:
  - test
  - report

variables:
  PIP_CACHE_DIR: "$CI_PROJECT_DIR/.cache/pip"
  npm_config_cache: "$CI_PROJECT_DIR/.cache/npm"

cache:
  paths:
    - .cache/pip
    - .cache/npm
    - node_modules/

unit-tests:
  stage: test
  image: node:18
  before_script:
    - npm ci
  script:
    - npm run test:unit -- --coverage
  coverage: '/Lines\s*:\s*(\d+\.\d+)%/'
  artifacts:
    reports:
      junit: junit.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml

integration-tests:
  stage: test
  image: node:18
  services:
    - postgres:14
    - redis:7
  variables:
    POSTGRES_DB: test_db
    POSTGRES_USER: postgres
    POSTGRES_PASSWORD: postgres
    DATABASE_URL: "postgresql://postgres:postgres@postgres:5432/test_db"
    REDIS_URL: "redis://redis:6379"
  script:
    - npm ci
    - npm run test:integration

e2e-tests:
  stage: test
  image: mcr.microsoft.com/playwright:v1.32.0-focal
  script:
    - npm ci
    - npm run test:e2e
  artifacts:
    when: on_failure
    paths:
      - test-results/
    expire_in: 1 week

test-report:
  stage: report
  image: node:18
  dependencies:
    - unit-tests
    - integration-tests
    - e2e-tests
  script:
    - npm run generate-report
  artifacts:
    paths:
      - test-report/
    expire_in: 30 days
```

## Jenkins

### Jenkinsfile

```groovy
// Jenkinsfile
pipeline {
    agent any

    environment {
        NODE_VERSION = '18'
        PYTHON_VERSION = '3.10'
    }

    stages {
        stage('Setup') {
            steps {
                sh '''
                    nvm install ${NODE_VERSION}
                    nvm use ${NODE_VERSION}
                    pyenv install ${PYTHON_VERSION}
                    pyenv local ${PYTHON_VERSION}
                '''
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                    npm ci
                    pip install -r requirements.txt
                '''
            }
        }

        stage('Parallel Tests') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        sh 'npm run test:unit'
                        junit 'reports/unit-tests.xml'
                    }
                }

                stage('Integration Tests') {
                    steps {
                        sh 'npm run test:integration'
                        junit 'reports/integration-tests.xml'
                    }
                }

                stage('Lint & Security') {
                    steps {
                        sh '''
                            npm run lint
                            npm audit
                            pip-audit
                        '''
                    }
                }
            }
        }

        stage('E2E Tests') {
            when {
                branch 'main'
            }
            steps {
                sh 'npm run test:e2e'
            }
        }

        stage('Performance Tests') {
            when {
                expression { params.RUN_PERFORMANCE_TESTS }
            }
            steps {
                sh 'npm run test:performance'
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'performance-report',
                    reportFiles: 'index.html',
                    reportName: 'Performance Report'
                ])
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '**/test-results/**', allowEmptyArchive: true
            publishHTML([
                allowMissing: false,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'coverage',
                reportFiles: 'index.html',
                reportName: 'Coverage Report'
            ])
        }

        failure {
            emailext(
                subject: "Build Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: "Check console output at ${env.BUILD_URL}",
                to: "${env.CHANGE_AUTHOR_EMAIL}"
            )
        }
    }
}
```

## CircleCI

### Configuration

```yaml
# .circleci/config.yml
version: 2.1

orbs:
  node: circleci/node@5.0.2
  python: circleci/python@2.1.1
  browser-tools: circleci/browser-tools@1.4.0

executors:
  test-executor:
    docker:
      - image: cimg/node:18.0
      - image: cimg/postgres:14.0
        environment:
          POSTGRES_USER: test
          POSTGRES_DB: test_db
      - image: cimg/redis:7.0

jobs:
  unit-tests:
    executor: test-executor
    steps:
      - checkout
      - node/install-packages
      - run:
          name: Run Unit Tests
          command: npm run test:unit -- --reporters=jest-junit
      - store_test_results:
          path: test-results
      - store_artifacts:
          path: coverage

  integration-tests:
    executor: test-executor
    steps:
      - checkout
      - node/install-packages
      - run:
          name: Wait for DB
          command: dockerize -wait tcp://localhost:5432 -timeout 1m
      - run:
          name: Run Integration Tests
          command: npm run test:integration
      - store_test_results:
          path: test-results

  e2e-tests:
    docker:
      - image: mcr.microsoft.com/playwright:v1.32.0-focal
    steps:
      - checkout
      - run:
          name: Install Dependencies
          command: npm ci
      - browser-tools/install-chrome
      - run:
          name: Run E2E Tests
          command: npm run test:e2e
      - store_artifacts:
          path: test-results
          when: on_fail

workflows:
  test-pipeline:
    jobs:
      - unit-tests
      - integration-tests:
          requires:
            - unit-tests
      - e2e-tests:
          requires:
            - integration-tests
          filters:
            branches:
              only:
                - main
                - develop
```

## Docker Integration

### Dockerfile for Testing

```dockerfile
# Dockerfile.test
FROM node:18-alpine AS base

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy source
COPY . .

# Test stage
FROM base AS test
RUN npm ci
RUN npm run test:unit
RUN npm run test:integration

# E2E test stage
FROM mcr.microsoft.com/playwright:v1.32.0-focal AS e2e
WORKDIR /app
COPY --from=base /app .
RUN npm ci
RUN npm run test:e2e

# Final stage
FROM base AS final
LABEL test-status="passed"
```

### Docker Compose for Test Environment

```yaml
# docker-compose.test.yml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.test
      target: test
    environment:
      - NODE_ENV=test
      - DATABASE_URL=postgresql://postgres:postgres@db:5432/test_db
      - REDIS_URL=redis://redis:6379
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    volumes:
      - ./test-results:/app/test-results
      - ./coverage:/app/coverage

  db:
    image: postgres:14
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: test_db
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  e2e:
    build:
      context: .
      dockerfile: Dockerfile.test
      target: e2e
    depends_on:
      - app
    environment:
      - BASE_URL=http://app:3000
    volumes:
      - ./test-results:/app/test-results
```

## Best Practices

### 1. Test Parallelization

- Run independent test suites in parallel
- Use test splitting for large test suites
- Leverage CI/CD matrix builds

### 2. Caching Strategy

- Cache dependencies between runs
- Use Docker layer caching
- Store test artifacts efficiently

### 3. Failure Handling

- Upload artifacts on failure
- Implement retry logic for flaky tests
- Send notifications for critical failures

### 4. Performance Optimization

- Use shallow git clones
- Minimize Docker image sizes
- Run only affected tests on PRs

### 5. Security

- Scan dependencies for vulnerabilities
- Use secrets management
- Implement SAST/DAST in pipeline

### 6. Reporting

- Generate comprehensive test reports
- Track test trends over time
- Monitor test execution times
