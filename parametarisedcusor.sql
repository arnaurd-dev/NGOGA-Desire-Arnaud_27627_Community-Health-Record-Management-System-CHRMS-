=== PARAMETERIZED CURSOR: WORKERS BY DEPARTMENT ===
==================================================
TEST 1: PEDIATRICS DEPARTMENT (All Salaries)
---------------------------------------------
Name: Alice Johnson
  Role: Doctor
  Salary: $50000
  Bonus: $5000
  Total: $55000
  Experience: 5 years
Name: Carol Davis
  Role: Nurse
  Salary: $35000
  Bonus: $3500
  Total: $38500
  Experience: 4 years
Workers found: 2
High earners (>$50K): 1

TEST 2: COMMUNITY OUTREACH (Salary >= $30,000)
-----------------------------------------------
Name: Grace Taylor
  Role: Community Health Worker
  Salary: $32000
  Department: Community Outreach
Name: Frank Miller
  Role: Community Health Worker
  Salary: $30000
  Department: Community Outreach
Workers found: 2
High earners (>$40K): 0

TEST 3: NON-EXISTENT DEPARTMENT (Should show no results)
-------------------------------------------------------
Workers found: 0


PL/SQL procedure successfully completed.

