class Chat {
  final String text;
  final bool isUser;

  Chat({
    required this.text,
    required this.isUser,
  });

  // Convert a Chat object into a list that can be stored in Hive
  List<dynamic> toHiveList() {
    return [
      text,
      isUser,
    ];
  }

  // Create a Chat object from a list retrieved from Hive
  factory Chat.fromHiveList(List<dynamic> hiveList) {
    return Chat(
      text: hiveList[0] as String,
      isUser: hiveList[1] as bool,
    );
  }

  // a clone method to create a new instance with the same values
  Chat clone() {
    return Chat(
      text: text,
      isUser: isUser,
    );
  }
}
