---
name: bolt-firebase-tdd
description: TDD patterns and architecture for Slack Bot development with Bolt for JavaScript on Firebase Functions (Cloud Functions for Firebase). Use when developing Slack commands/modals with Bolt for JS, deploying to Firebase Functions, writing tests for Slack Bot handlers, or needing mock patterns for Octokit/Bolt/Firebase.
---

# Bolt + Firebase Functions TDD

TDD development patterns for Slack Bot with Bolt for JavaScript on Firebase Functions.

## Architecture

```
Firebase Functions (HTTP)
  └── ExpressReceiver (processBeforeResponse: true)
       └── Bolt App
            ├── app.command() handlers
            └── app.view() handlers
```

Key configuration:

```javascript
const { App, ExpressReceiver } = require('@slack/bolt');
const functions = require('firebase-functions');

const receiver = new ExpressReceiver({
  signingSecret: process.env.SLACK_SIGNING_SECRET,
  processBeforeResponse: true, // Required for Firebase Functions
});

const app = new App({ token: process.env.SLACK_BOT_TOKEN, receiver });

// Register handlers...

exports.slack = functions.https.onRequest(receiver.app);
```

`processBeforeResponse: true` ensures Slack's 3-second timeout is met before async processing.

## TDD Workflow

For each new command or feature:

1. **Red**: Write test with mocked dependencies → confirm failure
2. **Green**: Implement minimal handler → confirm pass
3. **Refactor**: Clean up, extract constants → confirm still passing

Run tests: `cd tools/slack-bot && npx jest`

## Mock Patterns

See [references/mock-patterns.md](references/mock-patterns.md) for complete mock examples including:
- Bolt command/view handler capture
- Octokit singleton reset with `jest.resetModules()`
- Firebase Functions mock
- `jest.clearAllMocks()` for mock.calls accumulation prevention

## Command Handler Pattern

```javascript
// src/commands/example.js
const { someService } = require('../services/someService');

function registerExampleCommand(app) {
  app.command('/command-name', async ({ ack, command, respond }) => {
    await ack();
    // Parse args from command.text
    // Validate input
    // Call service
    // Respond to user
  });
}

module.exports = { registerExampleCommand };
```

## Testing a Command Handler

```javascript
jest.mock('../../src/services/someService');
const { someMethod } = require('../../src/services/someService');
const { registerExampleCommand } = require('../../src/commands/example');

describe('registerExampleCommand', () => {
  let app, commandHandler;

  beforeEach(() => {
    jest.clearAllMocks();
    app = { command: jest.fn() };
    registerExampleCommand(app);
    commandHandler = app.command.mock.calls.find(c => c[0] === '/command-name')[1];
    someMethod.mockResolvedValue({ /* mock data */ });
  });

  test('registers the command', () => {
    expect(app.command).toHaveBeenCalledWith('/command-name', expect.any(Function));
  });

  test('calls ack and responds', async () => {
    const ack = jest.fn();
    const respond = jest.fn();
    await commandHandler({ ack, command: { text: 'args' }, respond });
    expect(ack).toHaveBeenCalled();
    expect(respond).toHaveBeenCalledWith(expect.stringContaining('expected'));
  });
});
```

## Resources

### references/

- **[mock-patterns.md](references/mock-patterns.md)**: Detailed mock patterns for Octokit, Bolt, and Firebase Functions testing
