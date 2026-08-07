- split status code logic: first check authCode then status code !!! IMPORTANT !!!

- fix "message sending" queue when offline (some not sending)
- add "new user in chat" broadcast (serverside) to update member list client side
- fix notifications in push notifications

FOR LATER
- rewrite messageId logic (-> UUID instead of number)
- add signin / signout - when username taken check for sign in attempt rather then error and verify using password
- If Dilithium (ML-DSA) is secure for use, use it instead of Ed25519 (see https://pub.dev/packages/flutter_mldsa)
- Tutorial for setup usage: firebase setting + .env with IDkey setup