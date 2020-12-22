class LoginData {
  final int listID;
  final int userID;
  final Map<int, String> allItems;
  final List<int> completedItems;

  LoginData({this.listID, this.userID, this.allItems, this.completedItems});

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
        listID: json['list_id'],
        userID: json['user_id'],
        allItems: json['all_items'],
        completedItems: json['completed_items']);
  }
}
