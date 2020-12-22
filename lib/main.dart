import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

final String url = 'http://137.220.34.221:8080';

void main() => runApp(LoginInView());

Future<LoginData> fetchLogin(http.Client client, username) async {
  var map = new Map<String, dynamic>();
  map['username'] = username;
  final response = await client.post(url + '/login', body: map);
  if (response.statusCode == 200) {
    return LoginData.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Fail to get list info');
  }
}

Future<int> fetchCheck(http.Client client, itemID, userID) async {
  var map = new Map<String, dynamic>();
  map['item_id'] = itemID.toString();
  map['userID'] = userID.toString();
  final response = await client.post(url + '/checkItem', body: map);
  int ans = jsonDecode(response.body)['item_id'];
  print(ans);
  if (response.statusCode == 200) {
    return ans;
  } else {
    throw Exception('Fail to check item');
  }
}

Future<Item> fetchNew(http.Client client, userID, content) async {
  var map = new Map<String, dynamic>();
  map['userID'] = userID.toString();
  map['content'] = content.toString();
  final response = await client.post(url + '/newItem', body: map);
  print(response.body);
  if (response.statusCode == 200) {
    return Item.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Fail to create new item');
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => LoginInView(),
      },
    );
  }
}

class LoginInView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.deepPurple[600],
        accentColor: Colors.deepPurple[200],
        fontFamily: 'Times New Roman',
      ),
      home: Login(),
    );
  }
}

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String _username = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text('To-Do List!'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text('Enter your name: '),
              TextField(
                onChanged: (text) {
                  setState(() {
                    _username = text;
                  });
                },
              ),
              FloatingActionButton.extended(
                onPressed: () async {
                  LoginData data = await fetchLogin(http.Client(), _username);
                  setState(() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ToDo(info: data)),
                    );
                  });
                },
                label: Text('Go!'),
              )
            ],
          ),
        ));
  }
}

class ToDo extends StatefulWidget {
  final LoginData info;

  ToDo({Key key, @required this.info}) : super(key: key);

  @override
  _ToDoState createState() => _ToDoState();
}

class _ToDoState extends State<ToDo> {
  LoginData info;

  @override
  void initState() {
    setState(() {
      info = widget.info;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('To-Do List!'),
        ),
        body: ListView.builder(
          itemCount: info.getAllItems().length,
          itemBuilder: (context, index) {
            String content = info.getAllItems()[index].getText();
            int id = info.getAllItems()[index].getItemID();
            List<int> completed = info.getCompleted();
            if (completed.contains(id)) {
              return Container(
                child: ListTile(
                  title: Text(
                    content,
                  ),
                ),
                decoration: new BoxDecoration(
                  color: Colors.lightGreen,
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
              );
            } else {
              return Container(
                decoration: new BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: ListTile(
                  title: Text(content),
                  onTap: () {
                    _checkItem(id, info.getUserID());
                  },
                ),
              );
            }
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: _addItem,
        ),
        bottomNavigationBar: BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(
                  icon: Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    Navigator.pop(context);
                  }),
            ],
          ),
        ),
      ),
    );
  }

  void _addItem() {
    Navigator.of(context).push(MaterialPageRoute(builder: (content) {
      return Scaffold(
        appBar: new AppBar(title: new Text('New task')),
        body: new TextField(
          onSubmitted: (val) async {
            Navigator.pop(context);
            Item newItem = await fetchNew(http.Client(), info.userID, val);
            setState(() {
              info = info.addNew(newItem.getItemID(), newItem.getText());
              print(info);
            });
          },
        ),
      );
    }));
  }

  void _checkItem(itemID, userID) async {
    int item = await fetchCheck(http.Client(), itemID, userID);
    setState(() {
      info = info.completeNew(item);
      print(info);
    });
  }
}

class LoginData {
  final int listID;
  final int userID;
  final List<Item> allItems;
  final List<int> completedItems;

  LoginData({this.listID, this.userID, this.allItems, this.completedItems});

  factory LoginData.fromJson(Map<String, dynamic> json) {
    List<dynamic> items = json['all_items'];
    List<Item> allItems = [];
    for (int i = 0; i < items.length; i++) {
      allItems.add(new Item(id: items[i]['id'], text: items[i]['text']));
    }
    List<dynamic> comp = json['completed_items'];
    List<int> completed = [];
    for (int i = 0; i < comp.length; i++) {
      completed.add(comp[i]['id']);
    }
    return LoginData(
        listID: json['list_id'],
        userID: json['user_id'],
        allItems: allItems,
        completedItems: completed);
  }

  @override
  String toString() {
    return 'List id: ${listID}, User id: ${userID}, all items: ${allItems}, complete: ${completedItems}';
  }

  int getListID() {
    return listID;
  }

  int getUserID() {
    return userID;
  }

  List<dynamic> getAllItems() {
    return allItems;
  }

  List<dynamic> getCompleted() {
    return completedItems;
  }

  LoginData addNew(itemID, content) {
    print(content);
    this.allItems.add(new Item(id: itemID, text: content));
    return new LoginData(
        listID: this.listID,
        userID: this.userID,
        allItems: this.allItems,
        completedItems: this.completedItems);
  }

  LoginData completeNew(id) {
    this.completedItems.add(id);
    return new LoginData(
        listID: this.listID,
        userID: this.userID,
        allItems: this.allItems,
        completedItems: this.completedItems);
  }
}

class Item {
  final int id;
  final String text;

  Item({this.id, this.text});

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(id: json['id'], text: json['text']);
  }

  int getItemID() {
    return id;
  }

  String getText() {
    return text;
  }

  @override
  String toString() {
    return 'Item id: ${id}, text: ${text}';
  }
}
