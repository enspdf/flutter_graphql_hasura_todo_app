import 'package:flutter/material.dart';
import 'package:flutter_graphql_hasura_todo_app/components/todoCard.dart';
import 'package:flutter_graphql_hasura_todo_app/service/graphQldata.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

void main() => runApp(
      GraphQLProvider(
        client: graphQlObject.client,
        child: CacheProvider(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.dark(),
            home: TodoApp(),
          ),
        ),
      ),
    );

class TodoApp extends StatelessWidget {
  GraphQLClient client;
  final TextEditingController controller = TextEditingController();

  initMethod(context) {
    client = GraphQLProvider.of(context).value;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => initMethod(context));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'Tag',
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext buildContext1) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                title: Text('Add Task'),
                content: Form(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextField(
                        autofocus: true,
                        controller: controller,
                        decoration: InputDecoration(labelText: 'Task'),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: RaisedButton(
                            elevation: 7,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: Colors.black,
                            onPressed: () async {
                              await client.mutate(
                                MutationOptions(
                                  document: addTaskMutation(controller.text),
                                ),
                              );
                              controller.text = '';
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Add',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
      appBar: AppBar(
        centerTitle: true,
        title: Text('To-Do'),
      ),
      body: Center(
        child: Query(
          options: QueryOptions(document: fetchQuery(), pollInterval: 1),
          builder: (QueryResult result, {VoidCallback refetch}) {
            if (result.errors != null) {
              return Text(result.errors.toString());
            }

            if (result.loading) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else if (result.data != null && result.data['todo'].length == 0) {
              return Center(
                child: Text(
                  'No Todos Yet Added',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: result.data['todo'].length,
              itemBuilder: (BuildContext context, int index) {
                return TodoCard(
                  key: UniqueKey(),
                  task: result.data['todo'][index]['task'],
                  isCompleted: result.data['todo'][index]['isCompleted'],
                  delete: () async {
                    final Map<String, dynamic> response = (await client.mutate(
                      MutationOptions(
                        document: deleteTaskMutation(result, index),
                      ),
                    ))
                        .data;
                  },
                  toggleIsCompleted: () async {
                    final Map<String, dynamic> response = (await client.mutate(
                      MutationOptions(
                          document: toggleIsCompletedMutation(result, index)),
                    ))
                        .data;
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
