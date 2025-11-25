
Procedure ADD_NEW_VISIT compiled


Procedure UPDATE_WORKER_SALARY compiled


Procedure GENERATE_HEALTH_REPORT compiled

=== TESTING add_new_visit PROCEDURE ===
=====================================
Test 1: Adding normal visit
=== ADDING NEW VISIT ===
SUCCESS: New visit added successfully!
Visit ID: 2011
Patient: Mary Williams
Health Worker: Carol Davis (Pediatrics)
Diagnosis: Common Cold
Treatment: Rest and hydration
Visit Date: 25-NOV-2025 18:01

Test 2: Adding visit with minimal info
=== ADDING NEW VISIT ===
SUCCESS: New visit added successfully!
Visit ID: 2012
Patient: James Brown
Health Worker: Alice Johnson (Pediatrics)
Diagnosis: Routine Checkup
Treatment: Not specified
Visit Date: 25-NOV-2025 18:01

Test 3: Testing with invalid patient (should fail)
=== ADDING NEW VISIT ===
ERROR: Failed to add new visit - ORA-20001: Patient ID 9999 does not exist.
Expected error: ORA-20001: Patient ID 9999 does not exist.


PL/SQL procedure successfully completed.

