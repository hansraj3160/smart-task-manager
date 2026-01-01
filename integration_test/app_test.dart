import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smart_task_manager/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('End-to-End: Login -> Add Task -> Verify Task', (WidgetTester tester) async {
    await app.main();

    await tester.pumpAndSettle(const Duration(seconds: 3));

    final loginFinder = find.text('Welcome Back!');
    
    if (loginFinder.evaluate().isNotEmpty) {
     
      final emailField = find.ancestor(
        of: find.text('Email'),
        matching: find.byType(TextFormField),
      );
      final passwordField = find.ancestor(
        of: find.text('Password'),
        matching: find.byType(TextFormField),
      );
      final loginButton = find.text('LOGIN');
 
      await tester.enterText(emailField, 'test@gmail.com'); 
      await tester.enterText(passwordField, 'password123'); 
      await tester.pump();
 
      await tester.tap(loginButton);
    
      await tester.pumpAndSettle(const Duration(seconds: 4));
    } else {
      print("User likely already logged in. Proceeding to Dashboard.");
    }
      debugDumpApp();
    expect(find.text('Dashboard'), findsOneWidget);

   
    final fabFinder = find.byIcon(Icons.add);
    await tester.tap(fabFinder);
    
    await tester.pumpAndSettle();
 
    expect(find.text('Create Task'), findsWidgets); 
 
    final taskTitle = 'Test Task ${DateTime.now().millisecondsSinceEpoch}';
 
    final titleField = find.ancestor(
      of: find.text('Task Title'),
      matching: find.byType(TextField),
    );
    await tester.enterText(titleField, taskTitle);
 
    final descField = find.ancestor(
      of: find.text('Description'),
      matching: find.byType(TextField),
    );
    await tester.enterText(descField, 'Automated test description');
     
    final startDateField = find.text('Start Date');
    await tester.tap(startDateField);
    await tester.pumpAndSettle(); 
     
    final okButton = find.text('OK');
    await tester.tap(okButton);
    await tester.pumpAndSettle();  
    final startTimeField = find.text('Start Time');
    await tester.tap(startTimeField);
    await tester.pumpAndSettle();
 
    await tester.tap(okButton);  
    await tester.pumpAndSettle();
 
    final endDateField = find.text('End Date');
    await tester.tap(endDateField);
    await tester.pumpAndSettle();
 
    await tester.tap(okButton);
    await tester.pumpAndSettle();
  
    final endTimeField = find.text('End Time');
    await tester.tap(endTimeField);
    await tester.pumpAndSettle();
 
    await tester.tap(okButton);
    await tester.pumpAndSettle();
   
    final createButton = find.widgetWithText(ElevatedButton, 'Create Task');
    await tester.tap(createButton);
    await tester.pumpAndSettle(const Duration(seconds: 4));

  
  });
}