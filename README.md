# NAME: NGOGA DESIRE ARNAUD
# ID: 27627

## 🏥 **Project Title: Community Health Record Management System (CHRMS)**

### 📌 **Problem Statement**
Many rural or underserved communities lack a centralized system to manage patient health records, leading to:
- Inefficient tracking of patient visits, treatments, and medical history.
- Difficulty in generating health reports for community health workers.
- Poor management of medical supplies and allowances for health workers.

### 🎯 **Project Goal**
To build a PL/SQL-based database system that:
- Tracks patient visits, diagnoses, treatments, and health worker assignments.
- Manages health worker allowances and roles.
- Generates reports for community health analysis.

---

## 🗃️ **Database Schema**

### Tables:
1. **PATIENTS**
   - patient_id (PK)
   - first_name, last_name, date_of_birth, gender, contact

2. **HEALTH_WORKERS**
   - worker_id (PK)
   - first_name, last_name, role_id, department_id, salary

3. **VISITS**
   - visit_id (PK)
   - patient_id (FK)
   - worker_id (FK)
   - visit_date, diagnosis, treatment

4. **ALLOWANCES**
   - allowance_id (PK)
   - role_id (FK)
   - allowance_amount, effective_date

5. **ROLES**
   - role_id (PK)
   - role_name

6. **DEPARTMENTS**
   - department_id (PK)
   - department_name

---

## 🔧 **PL/SQL Components to Implement**

### 1. **Collections & Records**
- Use `VARRAY` to store up to 5 common diagnoses per patient.
- Use `%ROWTYPE` to manage health worker records.

### 2. **Functions**
- `get_patient_history(patient_id)` → Returns visit history as a cursor.
- `calculate_total_allowance(role_id)` → Returns total allowance for a role.
- `get_worker_full_name(worker_id)` → Returns formatted name.

### 3. **Procedures**
- `add_new_visit(patient_id, worker_id, diagnosis, treatment)`
- `update_worker_salary(worker_id, new_salary)`
- `generate_health_report(department_id)`

### 4. **Cursors**
- Explicit cursor to list all patients visited in a given month.
- Parameterized cursor to fetch workers by department.
- Cursor FOR loop to display health worker details.

### 5. **Exception Handling**
- Handle `NO_DATA_FOUND`, `TOO_MANY_ROWS`, and custom exceptions.
- Use `SQL%ROWCOUNT` and `SQL%NOTFOUND` to validate operations.

### 6. **Packages**
- Create a package `HEALTH_MGMT` to bundle related procedures and functions.

### 7. **BULK COLLECT & FORALL**
- Use `BULK COLLECT` to fetch all patients in a department.
- Use `FORALL` to update multiple health worker salaries at once.

---

## 📄 **Sample Code Snippets**

### 1. Record and VARRAY Example
```plsql
DECLARE
  TYPE diagnosis_list IS VARRAY(5) OF VARCHAR2(100);
  patient_diagnoses diagnosis_list := diagnosis_list('Malaria', 'Typhoid');
  worker_rec HEALTH_WORKERS%ROWTYPE;
BEGIN
  SELECT * INTO worker_rec FROM HEALTH_WORKERS WHERE worker_id = 101;
  DBMS_OUTPUT.PUT_LINE('Worker: ' || worker_rec.first_name);
END;
```

### 2. Function with Explicit Cursor
```plsql
CREATE OR REPLACE FUNCTION get_patient_visits(p_patient_id NUMBER)
RETURN SYS_REFCURSOR
IS
  visit_cursor SYS_REFCURSOR;
BEGIN
  OPEN visit_cursor FOR
    SELECT visit_date, diagnosis, treatment
    FROM VISITS
    WHERE patient_id = p_patient_id;
  RETURN visit_cursor;
END;
```

### 3. Procedure with Exception Handling
```plsql
CREATE OR REPLACE PROCEDURE add_visit(
  p_patient_id NUMBER,
  p_worker_id NUMBER,
  p_diagnosis VARCHAR2
) IS
BEGIN
  INSERT INTO VISITS (patient_id, worker_id, diagnosis, visit_date)
  VALUES (p_patient_id, p_worker_id, p_diagnosis, SYSDATE);

  IF SQL%ROWCOUNT = 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'No visit added.');
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
```

---

## 📊 **Sample Reports to Generate**
- Monthly visit summary per health worker.
- Total allowances per role.
- Patient treatment history.
- Department-wise health worker performance.

---

## 🚀 **Advanced Features**
- Use `DETERMINISTIC` functions for calculating allowances.
- Implement recursive function to find patient visit chains.
- Use `BULK_ROWCOUNT` and `BULK_EXCEPTIONS` in batch updates.

---

## 📁 **Project Deliverables**
1. Complete SQL script for table creation and sample data.
2. PL/SQL package with all procedures, functions, and cursors.
3. Anonymous blocks to test all components.
4. Documentation with example outputs and explanations.

---

## ✅ **Learning Coverage**
This project covers:
- Collections (VARRAY, nested tables, associative arrays)
- Records (table-based, user-defined, cursor-based)
- Functions (with and without DML, deterministic, recursive)
- Procedures (with parameters, exception handling)
- Cursors (implicit, explicit, parameterized, REF cursors)
- Bulk operations (BULK COLLECT, FORALL)
- Exception handling and cursor attributes
- Packages and modular programming
