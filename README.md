# MyTradeChatSpammer

MyTradeChatSpammer is a World of Warcraft addon for storing trade messages and posting them to Trade chat in a rotating loop.

## What it does

- Stores reusable ad messages per character.
- Lets you manage messages in a simple UI.
- Can post messages to Trade chat on a timed loop when enabled.
- Supports slash commands for basic message management.

![UI](https://raw.githubusercontent.com/MyGamesDevelopmentAcc/MyTradeChatSpammer/main/.previews/ui.png)

## Opening the addon

- Click the addon in the Addon Compartment menu (top-right addon icon area).
- This opens the main message-management window.

## UI usage

1. Enter an `Id` (optional) and message text.
2. If you leave `Id` empty, the addon auto-generates IDs like `#0`, `#1`, etc.
3. Saving with an existing `Id` overwrites that entry.
4. Click `Save` to add/update a message.
5. Select a row in the list to load it back into the input fields.
6. Click `Delete` to remove the message by current `Id`.
7. Use the `Filter` box to search by `Id` or message content.
8. Click `Start spamming` / `Stop spamming` to toggle the posting loop.

## Slash commands

Base command: `/mtcs`

- `/mtcs r <message>`
  - Save a message with an auto-generated ID.
- `/mtcs record <id> <message>`
  - Save/update a message with a specific ID.
- `/mtcs delete <id>`
  - Delete a saved message.
- `/mtcs print [id]`
  - Print all saved messages, or one saved message when `id` is provided.
- `/mtcs send`
  - Send the next saved message.
- `/mtcs send <id> [chatType]`
  - Send one saved message by ID.
- `/mtcs toggle`
  - Toggle automatic spam mode.

## Spamming behavior

- Spam loop runs only while both are true:
  - spam is enabled
  - you are currently in `Trade - City`
- On enable, it allows one immediate post by setting the message counter to the threshold.
- After each send it counts the number of messages other players have posted as well as waits not to overspam the trade channel with messages.
- The messages are sent only when you actively play the game, ie. press buttons.

## License

See `LICENSE.md`.
