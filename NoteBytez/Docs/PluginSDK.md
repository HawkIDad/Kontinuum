<!-- PluginSDK.md -->
<!--
  Developer reference for NoteBytez's Plugin SDK (Preview), per
  Docs/Plans/NoteBytez-R1-Implementation.md Phase 13. Describes the permission model and the
  three bridge APIs a plugin script can be granted. Not an implementation plan — see that file's
  Decisions Log #3 for the design rationale.
-->

# NoteBytez Plugin SDK (Preview)

> **Breaking change (pre-release rename):** the bridge global was named `noteBytez` in earlier
> pre-release builds. It is now `noteBytez`. Update any script written against the old name —
> there is no compatibility alias.

A plugin is a small `JavaScriptCore` script, sandboxed behind a minimal, explicitly-permissioned
bridge. There is no filesystem access, no network access, and no background execution — a script
only ever runs synchronously, in direct response to something the user did.

## Permission model

At install time (Settings → Plugins → Add), the user is shown every permission the plugin's
script can be granted and approves them individually — see `PluginPermissionRow`. There is no
single "trust this plugin" toggle. A plugin's granted permissions are fixed at install: to change
them, uninstall and reinstall.

Three permissions exist, matching the three bridge APIs below:

| Permission | Unlocks |
|---|---|
| **Read library** | `listDocuments`, `searchDocuments`, `listTags`, `listNotebooks` |
| **Write current note** | `appendToCurrentNote`, `insertAtCursor` |
| **Add command** | `addCommand` |

Every bridge function is always defined on the `noteBytez` global, whether or not its permission
was granted — calling one without the permission throws a JS `Error` ("Permission denied: …")
rather than the function simply being absent. This is deliberate: sandbox enforcement happens at
the bridge layer itself (`PluginBridge.installBridge`), not by omission, so a script can't infer
what it might have been granted by probing for `typeof noteBytez.someFunction`.

## Execution model

A script runs once per invocation, with no state kept between runs — no live callback function
is ever held onto. There are exactly two ways a script gets run:

1. **Registration** — `noteBytez.invokedCommand` is `null`. The script is expected to call
   `noteBytez.addCommand(name)` once per command it offers. This is how NoteBytez discovers what
   a plugin can do.
2. **Invocation** — `noteBytez.invokedCommand` is set to the name of the command the user picked.
   The script re-runs from the top; it's expected to branch on `noteBytez.invokedCommand` and do
   the actual work for that one command.

Every invocation re-checks permissions from scratch, since nothing about a script persists
between runs.

A script has `PluginBridge.executionTimeLimit` (2 seconds) to finish. Apple's public
`JavaScriptCore` API has no supported way to forcibly interrupt a running script, so a script
that hangs (e.g. an infinite loop) simply causes the *host* to stop waiting and move on — the
runaway script itself is abandoned, not killed, and anything it does after the timeout (further
`noteBytez.*` calls) is discarded rather than applied. The host app itself never hangs or crashes
because of a plugin script; a truly hostile infinite loop leaks one background thread, which is
an accepted, documented limitation rather than a solved one — see `PluginRunResult.timedOut`.

## The three bridge APIs

### Read library (`.readLibrary`)

Read-only. No write methods are exposed under this permission, by design.

```js
noteBytez.listDocuments()          // -> [{ id, title }, ...]
noteBytez.searchDocuments(query)   // -> [{ id, title }, ...], matches title or content
noteBytez.listTags()               // -> [String]
noteBytez.listNotebooks()          // -> [String]
```

### Write current note (`.writeCurrentNote`)

Append-only or insert — never arbitrary file access, and never any document other than whichever
one is currently open when the command runs.

```js
noteBytez.appendToCurrentNote(text)   // -> Bool
noteBytez.insertAtCursor(text)        // -> Bool
```

**Preview-scope limitation**: NoteBytez's editor doesn't yet track cursor position, so a script
has no way to know where "the cursor" actually is — `insertAtCursor` is accepted as a distinct
call for forward API compatibility, but today the host applies it exactly like an append. This is
a real, current gap, not a hidden implementation detail.

### Add command (`.addCommand`)

```js
noteBytez.addCommand(name)   // -> Bool
```

Registers `name` as a command NoteBytez knows this plugin can run. Call this once per command
during the registration pass (see "Execution model" above).

## Example plugin: Word Count

```js
if (noteBytez.invokedCommand === null) {
  noteBytez.addCommand("Insert Word Count");
} else if (noteBytez.invokedCommand === "Insert Word Count") {
  var docs = noteBytez.listDocuments();
  noteBytez.appendToCurrentNote("Library has " + docs.length + " notes.");
}
```

Requires **Read library** and **Write current note**; does not need **Add command** to be
*invoked* (only to register), so a minimal single-purpose plugin still needs all three if it
wants to appear as a named command at all — a plugin that only ever runs once with no picker
affordance can skip `addCommand` and just do its work unconditionally, but then NoteBytez has no
way to invoke it after registration, so this is not a realistic pattern in practice.
