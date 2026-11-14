---
name: grilling
description: Grill the user relentlessly about a plan, decision, or idea. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases.
metadata:
  local-fork: "one-question-at-a-time"
---

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it, and settle the dependencies between decisions one at a time.

Ask the questions one at a time, waiting for my answer before continuing. Asking multiple questions at once is bewildering. For each question, give your recommended answer, worded so "yes" accepts it.

Format each question like so:

```
❓ **<question title>**: <question body, might be multiple paragraphs, including multiple choices>

➡️ <your recommended answer>
```

Each answer reshapes the tree: settled decisions unblock the next question. Ask that next question, and keep descending until every branch is resolved.

Finding _facts_ is your job, never the user's. When a question needs a fact from the environment (filesystem, tools, etc.), look it up yourself or dispatch a sub-agent with a fresh context window to find it; don't ask the user for anything you could look up. The _decisions_ are the user's: put each one to them and wait for my answer.

The session is done when every branch of the design tree is visited and nothing is left silently assumed. Do not act on it until the user confirms you have reached a shared understanding.
