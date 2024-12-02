import 'package:flutter/material.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class Task {
  String title;
  bool isDone;

  Task({required this.title, this.isDone = false});
}

class _TasksPageState extends State<TasksPage> {
  List<String> days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  int selectedDayIndex = 0;
  List<List<Task>> tasks = [
    [
      Task(title: "Gullaga suv quyib qoyish"),
      Task(title: "Delever Integratsiya qilish"),
      Task(title: "Mobile Application Yasash"),
      Task(title: "Sieves 3chi versiyaga davom etish"),
      Task(title: "Task 5")
    ],
    [Task(title: "Task 3")],
    [Task(title: "Task 4"), Task(title: "Task 5"), Task(title: "Task 6")],
    [],
    [Task(title: "Task 7")],
    [Task(title: "Task 8"), Task(title: "Task 9")],
    [Task(title: "Task 10")]
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/homepage');
          },
        ),
        actions: [
          IconButton(
            icon: CircleAvatar(
              backgroundImage: AssetImage('images/ava.png'), //.png required
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/profilepage');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 100.0,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDayIndex = index;
                    });
                  },
                  child: Card(
                    margin: EdgeInsets.all(10),
                    color:
                        selectedDayIndex == index ? Colors.blue : Colors.white,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(25.0),
                        child: Text(
                          days[index],
                          style: TextStyle(
                            color: selectedDayIndex == index
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tasks[selectedDayIndex].length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    tasks[selectedDayIndex][index].title,
                    style: TextStyle(
                      decoration: tasks[selectedDayIndex][index].isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  trailing: Checkbox(
                    value: tasks[selectedDayIndex][index].isDone,
                    onChanged: (bool? value) {
                      setState(() {
                        tasks[selectedDayIndex][index].isDone = value ?? false;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
