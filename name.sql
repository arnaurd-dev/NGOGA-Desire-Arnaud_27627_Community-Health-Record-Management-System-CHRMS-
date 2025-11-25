=== TESTING get_patient_history FUNCTION ===
===========================================
Patient: John Doe

Fetching visit history for patient ID: 1001
VISIT HISTORY:
-------------
Visit ID: 2009
Date: 10-MAR-2024
Diagnosis: Follow-up
Treatment: Health education
Health Worker: Frank Miller
Department: Community Outreach
Notes: Community follow-up visit
---
Visit ID: 2001
Date: 15-JAN-2024
Diagnosis: Malaria
Treatment: Antimalarial medication
Health Worker: Alice Johnson
Department: Pediatrics
Notes: Patient responded well to treatment
---
End of visit history.


PL/SQL procedure successfully completed.

=== TESTING get_worker_full_name FUNCTION ===
===========================================
Getting full name for worker ID: 101
Formatted name: Alice Johnson (Doctor)
Worker ID: 101
Formatted Name: Alice Johnson (Doctor)
Department: Pediatrics
Salary: $50000
---
Getting full name for worker ID: 102
Formatted name: Bob Smith (Doctor)
Worker ID: 102
Formatted Name: Bob Smith (Doctor)
Department: General Medicine
Salary: $55000
---
Getting full name for worker ID: 103
Formatted name: Carol Davis (Nurse)
Worker ID: 103
Formatted Name: Carol Davis (Nurse)
Department: Pediatrics
Salary: $35000
---
Getting full name for worker ID: 104
Formatted name: David Wilson (Nurse)
Worker ID: 104
Formatted Name: David Wilson (Nurse)
Department: Maternity
Salary: $38000
---
Testing with invalid worker ID:
Getting full name for worker ID: 999
No health worker found with ID: 999
Result: Unknown Worker


PL/SQL procedure successfully completed.

