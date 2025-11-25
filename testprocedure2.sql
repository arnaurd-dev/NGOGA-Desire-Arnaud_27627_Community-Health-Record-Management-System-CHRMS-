=== TESTING update_worker_salary PROCEDURE ===
============================================
Current salary: $55000
Test 1: 10% salary increase
=== UPDATING WORKER SALARY ===
SUCCESS: Salary updated successfully!
Worker: Bob Smith
Role: Doctor
Department: General Medicine
Old Salary: $55000
New Salary: $60500
Salary Change: $5500
Percentage Change: 10%

Test 2: 25% salary increase (should trigger notice)
=== UPDATING WORKER SALARY ===
SUCCESS: Salary updated successfully!
Worker: Bob Smith
Role: Doctor
Department: General Medicine
Old Salary: $60500
New Salary: $68750
Salary Change: $8250
Percentage Change: 13.64%

Test 3: Testing with negative salary (should fail)
=== UPDATING WORKER SALARY ===
ERROR: Failed to update salary - ORA-20003: Invalid salary amount: -1000
Expected error: ORA-20003: Invalid salary amount: -1000

Note: All changes rolled back for testing purposes.


PL/SQL procedure successfully completed.

