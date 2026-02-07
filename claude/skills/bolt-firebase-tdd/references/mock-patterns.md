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

For testing `app.js` that exports a Cloud Function:

```javascript
jest.mock('@slack/bolt');
jest.mock('firebase-functions', () => ({
  https: { onRequest: jest.fn((handler) => handler) },
}));

const { App, ExpressReceiver } = require('@slack/bolt');

// Mock ExpressReceiver with .app property
const mockExpressApp = { use: jest.fn() };
ExpressReceiver.mockImplementation(() => ({ app: mockExpressApp }));

// Mock App with command/view registration
App.mockImplementation(() => ({
  command: jest.fn(),
  view: jest.fn(),
}));

describe('app.js', () => {
  test('creates ExpressReceiver with processBeforeResponse', () => {
    jest.resetModules();
    jest.mock('@slack/bolt');
    jest.mock('firebase-functions', () => ({
      https: { onRequest: jest.fn((h) => h) },
    }));
    // Re-setup mocks...
    require('../../src/app');
    expect(ExpressReceiver).toHaveBeenCalledWith(
      expect.objectContaining({ processBeforeResponse: true })
    );
  });
});
```

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

### Environment variable cleanup

Always clean up env vars in `afterEach` to prevent test pollution:

```javascript
afterEach(() => {
  delete process.env.MY_VAR;
});
```
