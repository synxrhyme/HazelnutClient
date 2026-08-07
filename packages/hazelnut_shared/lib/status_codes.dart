// ignore_for_file: constant_identifier_names

class StatusCodes {
  static const int AUTH_SUCCESS = 0; // NOT USED
  static const int AUTH_USER_NOT_FOUND = 1;
  static const int AUTH_INVALID_TOKEN_FOR_USERID = 2;
  static const int AUTH_TOKEN_EXPIRED = 3;
  static const int AUTH_UNKNOWN_ERROR = 4;

  static const int CHAT_ALREADY_EXISTS = 100;
  static const int CHAT_CREATION_SUCCESSFUL = 101;

  static const int CHAT_NOT_FOUND = 200;
  static const int CHAT_WRONG_PASSWORD = 201;
  static const int CHAT_ALREADY_JOINED = 202;
  static const int CHAT_JOIN_SUCCESSFUL = 203;

  static const int MESSAGE_SENT_SUCCESSFULLY = 300;
  static const int MESSAGE_ID_TAKEN = 301;

  static const int SYNC_MESSAGES_SUCCESS = 400;
}