# Mock Patterns

## Table of Contents

- [Octokit Singleton Mock](#octokit-singleton-mock)
- [Bolt Command Handler Capture](#bolt-command-handler-capture)
- [Bolt View Handler Capture](#bolt-view-handler-capture)
- [Firebase Functions Mock](#firebase-functions-mock)
- [Common Pitfalls](#common-pitfalls)

## Octokit Singleton Mock

Octokit is typically a singleton. Use `jest.resetModules()` in `beforeEach` to reset the module cache, ensuring each test gets a fresh instance.

```javascript
jest.mock('@octokit/rest');

describe('githubService', () => {
  let mockCreate, mockListForRepo, mockGetContent;
  let mockGetRef, mockGetCommit, mockCreateTree, mockCreateCommit, mockUpdateRef;

  beforeEach(() => {
    jest.resetModules();          // Reset singleton
    jest.mock('@octokit/rest');    // Re-register mock

    process.env.GITHUB_TOKEN = 'test-token';
    process.env.GITHUB_OWNER = 'test-owner';
    process.env.GITHUB_REPO = 'test-repo';

    mockCreate = jest.fn().mockResolvedValue({
      data: { html_url: 'https://github.com/owner/repo/issues/1', number: 1 },
    });
    mockGetContent = jest.fn();
    mockGetRef = jest.fn();
    mockGetCommit = jest.fn();
    mockCreateTree = jest.fn();
    mockCreateCommit = jest.fn();
    mockUpdateRef = jest.fn();

    const { Octokit: MockOctokit } = require('@octokit/rest');
    MockOctokit.mockImplementation(() => ({
      rest: {
        issues: { create: mockCreate, listForRepo: jest.fn() },
        repos: { getContent: mockGetContent },
        git: {
          getRef: mockGetRef,
          getCommit: mockGetCommit,
          createTree: mockCreateTree,
          createCommit: mockCreateCommit,
          updateRef: mockUpdateRef,
        },
      },
    }));
  });

  afterEach(() => {
    delete process.env.GITHUB_TOKEN;
    delete process.env.GITHUB_OWNER;
    delete process.env.GITHUB_REPO;
  });

  test('example', async () => {
    // require AFTER mock setup
    const { createIssue } = require('../../src/services/githubService');
    const result = await createIssue({ title: 'Test', body: 'Body', labels: [] });
    expect(mockCreate).toHaveBeenCalledWith(expect.objectContaining({ title: 'Test' }));
  });
});
```

**Key point**: Always `require()` the module under test INSIDE the test or in `beforeEach` AFTER mock setup.

## Bolt Command Handler Capture

Capture registered command handlers via `app.command` mock:

```javascript
jest.mock('../../src/services/someService');
const { someMethod } = require('../../src/services/someService');
const { registerCommand } = require('../../src/commands/example');

describe('command', () => {
  let app, commandHandler;

  beforeEach(() => {
    jest.clearAllMocks();   // Prevents mock.calls accumulation
    app = { command: jest.fn() };
    registerCommand(app);
    // Extract the handler function (2nd argument of the matching call)
    commandHandler = app.command.mock.calls.find(c => c[0] === '/command-name')[1];
    someMethod.mockResolvedValue({ /* data */ });
  });

  test('handler invocation', async () => {
    const ack = jest.fn();
    const respond = jest.fn();
    await commandHandler({ ack, command: { text: 'input' }, respond });
    expect(ack).toHaveBeenCalled();
    expect(respond).toHaveBeenCalledWith(expect.stringContaining('expected'));
  });
});
```

## Bolt View Handler Capture

For modal submissions (app.view):

```javascript
beforeEach(() => {
  jest.clearAllMocks();
  app = { command: jest.fn(), view: jest.fn() };
  registerCommand(app);
  viewHandler = app.view.mock.calls.find(c => c[0] === 'modal_callback_id')[1];
});

test('modal submission', async () => {
  const ack = jest.fn();
  const body = {
    user: { id: 'U123', username: 'testuser' },
    view: {
      state: {
        values: {
          block_id: {
            action_id: { value: 'user input' },
          },
        },
      },
    },
  };
  await viewHandler({ ack, body, view: body.view });
  expect(ack).toHaveBeenCalled();
});
```

## Firebase Functions Mock

For testing `app.js` that exports a Cloud Function with `region()` + `runWith()` chain:

```javascript
jest.mock('@slack/bolt');
jest.mock('firebase-functions');
jest.mock('../src/commands/problem', () => ({ registerProblemCommand: jest.fn() }));
// ... other command mocks

describe('app.js', () => {
  let mockExpressApp;

  beforeEach(() => {
    jest.resetModules();
    jest.mock('@slack/bolt');
    jest.mock('firebase-functions');
    // ... re-register command mocks

    process.env.SLACK_BOT_TOKEN = 'xoxb-test';
    process.env.SLACK_SIGNING_SECRET = 'test-secret';

    mockExpressApp = { use: jest.fn() };

    const { ExpressReceiver: MockReceiver } = require('@slack/bolt');
    MockReceiver.mockImplementation(() => ({ app: mockExpressApp }));

    const { App: MockApp } = require('@slack/bolt');
    MockApp.mockImplementation(() => ({ command: jest.fn(), view: jest.fn() }));

    // Mock the full chain: functions.region().runWith().https.onRequest()
    const mockFunctions = require('firebase-functions');
    const mockOnRequest = jest.fn((handler) => handler);
    const mockRunWith = jest.fn(() => ({
      https: { onRequest: mockOnRequest },
    }));
    mockFunctions.region = jest.fn(() => ({
      runWith: mockRunWith,
    }));
    mockFunctions._mockOnRequest = mockOnRequest;
    mockFunctions._mockRunWith = mockRunWith;
  });

  test('exports with region, secrets, and onRequest', () => {
    const mockFunctions = require('firebase-functions');
    const appModule = require('../src/app');

    expect(mockFunctions.region).toHaveBeenCalledWith('asia-northeast1');
    expect(mockFunctions._mockRunWith).toHaveBeenCalledWith({
      secrets: expect.arrayContaining(['SLACK_BOT_TOKEN', 'GITHUB_TOKEN']),
    });
    expect(mockFunctions._mockOnRequest).toHaveBeenCalledWith(mockExpressApp);
    expect(appModule.slack).toBeDefined();
  });
});
```

### Chain structure

`functions.region().runWith().https.onRequest()` — each step returns an object with the next method. The mock must replicate this chain.

## Common Pitfalls

### mock.calls accumulation across tests

Without `jest.clearAllMocks()` in `beforeEach`, mock call history persists. If test B reads `mock.calls[0]`, it may get test A's call instead.

```javascript
beforeEach(() => {
  jest.clearAllMocks();  // Always add this
});
```

### Singleton not resetting

If a module caches an instance (e.g., `let octokit;`), `jest.clearAllMocks()` alone is insufficient. Use `jest.resetModules()` to reset the module cache.

### require() timing

When using `jest.resetModules()`, `require()` the module AFTER mock setup, not at the top of the file. Top-level requires run before `beforeEach`.

### Firebase deploy fails with Bolt initialization error

`firebase deploy` はソースを `require()` して export を解析する。この時点では secrets が注入されていないため、Bolt の `new App({ token })` が `token` なしでクラッシュする。

**解決**: プレースホルダーを設定する:

```javascript
const app = new App({
  token: process.env.SLACK_BOT_TOKEN || 'placeholder',
  receiver,
});
```

### Secrets not available at runtime

`firebase functions:secrets:set` でシークレットを保存しても、`runWith({ secrets })` を宣言しないと `process.env` に注入されない。

```javascript
// NG: secrets が process.env に入らない
exports.slack = functions.https.onRequest(receiver.app);

// OK: secrets が process.env に注入される
exports.slack = functions
  .runWith({ secrets: ['SLACK_BOT_TOKEN', 'GITHUB_TOKEN'] })
  .https.onRequest(receiver.app);
```

### Environment variable cleanup

Always clean up env vars in `afterEach` to prevent test pollution:

```javascript
afterEach(() => {
  delete process.env.MY_VAR;
});
```
