=== TESTING generate_health_report PROCEDURE ===
==============================================
Test 1: Pediatrics Department Report
=== GENERATING HEALTH DEPARTMENT REPORT ===
==========================================
DEPARTMENT: Pediatrics
Report Date: 25-NOV-2025 18:13
===================================================
DEPARTMENT SUMMARY:
  Total Health Workers: 2
  Total Patients Served: 4
  Total Visits: 5
  Average Salary: $47000
  Total Allowances: $27000

HEALTH WORKERS IN DEPARTMENT:
  Name                     Salary    Experience
  ---------------------------------------------
  Alice Johnson            $50000    5 years
  Carol Davis              $35000    4 years

RECENT VISITS (Last 3 Months):
  Date        Patient             Health Worker       Diagnosis
  ------------------------------------------------------------
  25-NOV      James Brown         Alice Johnson       Routine Checkup
  25-NOV      Mary Williams       Carol Davis         Common Cold

COMMON DIAGNOSES:
  Diagnosis                Frequency
  ----------------------------------
  Malaria                  2
  Routine Checkup          1
  Common Cold              1
  Hypertension             1

=== REPORT GENERATION COMPLETE ===

=============================================================

Test 2: General Medicine Department Report
=== GENERATING HEALTH DEPARTMENT REPORT ===
==========================================
DEPARTMENT: General Medicine
Report Date: 25-NOV-2025 18:13
===================================================
DEPARTMENT SUMMARY:
  Total Health Workers: 2
  Total Patients Served: 2
  Total Visits: 2
  Average Salary: $60833.33
  Total Allowances: $22000

HEALTH WORKERS IN DEPARTMENT:
  Name                     Salary    Experience
  ---------------------------------------------
  Bob Smith                $68750    6 years
  Henry Anderson           $45000    3 years

RECENT VISITS (Last 3 Months):
  Date        Patient             Health Worker       Diagnosis
  ------------------------------------------------------------

COMMON DIAGNOSES:
  Diagnosis                Frequency
  ----------------------------------
  Typhoid                  1
  Diabetes                 1

=== REPORT GENERATION COMPLETE ===

=============================================================

Test 3: Testing with invalid department (should fail)
=== GENERATING HEALTH DEPARTMENT REPORT ===
==========================================
ERROR: Failed to generate report - ORA-20005: Department ID 999 does not exist.
Expected error: ORA-20005: Department ID 999 does not exist.


PL/SQL procedure successfully completed.

