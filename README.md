# EmberWrite

Fun side project making use of the ChatGPT API.

Currently hard-coded to use ChatGPT 3.5.

Some features you get that the official web interface doesn't give you:

- Uses API key so it can be chaper than pro in most cases.
- Allows you to edit all previous chats, including assistant. This makes shaping the desired responses easier as it likes to follow an established pattern.
- Visual difference between messages that are in-context and out of context. Out of context messages aren't sent to the API endpoint, and so don't factor into your chat completion.
- Chat is locally saved on your machine.
- Not a web app. Call me old-fashioned, but I prefer native apps.
- Little beep and boop sound when sending and receiving messages.

Some features that the official interface has that this doesn't:

- Multiple chats. Right now you can only have one chat. Manage the chat files yourself with your native file explorer to handle multiple chats.
- Re-do last response. You can re-load the chat from disk, but not re-send for a replacement response from the server unless you hand-edit the chat on disk and re-do your own response in the chat window.
- Estimation of how many tokens are in the sent message is just an estimate. Since I don't do Python. Sometimes you will get a warning pop-up that the message exceeds tokens allowed for context. Just click the warning to make it go away and it will automatically send for a new message with reduced context.
- Does not stream the response. You will have to wait a moment for the full response to appear all at once, instead of typing out slowly over time. There will often be a pause between hitting the send button and getting a response. Be patient. Sometimes the wait is a long one. Sometimes you'll get a 502 warning instead of a reponse. You should always get at least something eventually.
- No pretty user feedback in uncommon situations. You get raw error messages. I'm the only target audience for this app. These messages make sense to me.

# Building

You will need Qt Creator and Qt 6.4 or later to build this project.

Tested on Windows, but you can probably also build this successfully for Linux, Android, macOS, and iOS if you have some experience doing that.

# Files

Uses the local writable file directory to save its files.
On Windows, that's:

C:\Users\<USERNAME>\AppData\Roaming\EmberWrite

The chat.json file is the full contents of your chat inside a json array. This is what gets loaded to the app to view, and also the most recent messages are used to define the context that is sent to the API to request a completion.

Create a file in this directory named "apikey" and paste your key inside that file in order for this program to work.

Most warning pop-ups are also appended to warnings.txt. This will mostly be context length warnings from the API, but sometimes you'll get a 502 error when the server is busy.