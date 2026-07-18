- Fix random problems with Debug disconnect (physical + emulator) 
- fix firebase multiple init -> race condition (sometimes) - 

"I/FLTFireMsgService(28629): FlutterFirebaseMessagingBackgroundService started!
 W/FLTFireMsgService(28629): Attempted to start a duplicate background isolate. Returning...
"

- fix messages not being displayed (from own user)
- fix "message sending" queue when offline
- check and maybe rewrite entire chat- and message-provider logic as well as database access
- add "new user in chat" broadcast (serverside) to update member list client side
- fix notification counter in push notifications when app is fully closed (firebase isolate)

FOR LATER
- add signin / signout - when username taken check for sign in attempt rather then error and verify using password
- If Dilithium (ML-DSA) is secure for use, use it instead of Ed25519 (see https://pub.dev/packages/flutter_mldsa)
- Tutorial for setup usage: firebase setting + .env with IDkey setup