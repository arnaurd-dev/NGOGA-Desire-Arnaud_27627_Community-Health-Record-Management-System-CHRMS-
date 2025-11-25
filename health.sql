DECLARE
    -- VARRAY for diagnoses
    patient_diagnoses diagnosis_array;
    
    -- %ROWTYPE for patient
    patient_rec PATIENTS%ROWTYPE;
    
    -- %ROWTYPE for health worker
    worker_rec HEALTH_WORKERS%ROWTYPE;
    
    -- Counter
    i NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== COMBINING VARRAY AND %ROWTYPE ===');
    DBMS_OUTPUT.PUT_LINE('====================================');
    
    -- Get patient information
    SELECT * INTO patient_rec 
    FROM PATIENTS 
    WHERE patient_id = 1001;
    
    -- Get the health worker who treated this patient most recently
    SELECT hw.* INTO worker_rec
    FROM HEALTH_WORKERS hw
    JOIN VISITS v ON hw.worker_id = v.worker_id
    WHERE v.patient_id = patient_rec.patient_id
    AND v.visit_date = (SELECT MAX(visit_date) FROM VISITS WHERE patient_id = patient_rec.patient_id);
    
    -- Get patient diagnoses using VARRAY
    SELECT diagnosis 
    BULK COLLECT INTO patient_diagnoses
    FROM (
        SELECT DISTINCT diagnosis 
        FROM VISITS 
        WHERE patient_id = patient_rec.patient_id 
        AND diagnosis IS NOT NULL
        ORDER BY diagnosis
    ) WHERE ROWNUM <= 5;
    
    -- Display combined information
    DBMS_OUTPUT.PUT_LINE('PATIENT INFORMATION:');
    DBMS_OUTPUT.PUT_LINE('  Name: ' || patient_rec.first_name || ' ' || patient_rec.last_name);
    DBMS_OUTPUT.PUT_LINE('  Gender: ' || patient_rec.gender);
    DBMS_OUTPUT.PUT_LINE('  Contact: ' || patient_rec.contact);
    DBMS_OUTPUT.PUT_LINE('  Registered: ' || TO_CHAR(patient_rec.registration_date, 'DD-MON-YYYY'));
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('PRIMARY HEALTH WORKER:');
    DBMS_OUTPUT.PUT_LINE('  Name: ' || worker_rec.first_name || ' ' || worker_rec.last_name);
    DBMS_OUTPUT.PUT_LINE('  Role: ' || worker_rec.role_id);
    DBMS_OUTPUT.PUT_LINE('  Contact: ' || worker_rec.email);
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('PATIENT DIAGNOSES (' || patient_diagnoses.COUNT || '):');
    IF patient_diagnoses.COUNT > 0 THEN
        FOR i IN 1..patient_diagnoses.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE('  ' || i || '. ' || patient_diagnoses(i));
        END LOOP;
    ELSE
        DBMS_OUTPUT.PUT_LINE('  No diagnoses recorded.');
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('VARRAY Status:');
    DBMS_OUTPUT.PUT_LINE('  Current size: ' || patient_diagnoses.COUNT);
    DBMS_OUTPUT.PUT_LINE('  Maximum capacity: ' || patient_diagnoses.LIMIT);
    DBMS_OUTPUT.PUT_LINE('  Available slots: ' || (patient_diagnoses.LIMIT - patient_diagnoses.COUNT));

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: Required data not found.');
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('Error: Multiple records found where one was expected.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/




-- Function to get patient visit history as a REF CURSOR
CREATE OR REPLACE FUNCTION get_patient_history(
    p_patient_id IN NUMBER
) RETURN SYS_REFCURSOR
IS
    visit_cursor SYS_REFCURSOR;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Fetching visit history for patient ID: ' || p_patient_id);
    
    -- Open cursor for the patient's visit history
    OPEN visit_cursor FOR
    SELECT 
        v.visit_id,
        v.visit_date,
        v.diagnosis,
        v.treatment,
        v.notes,
        hw.first_name || ' ' || hw.last_name AS health_worker_name,
        d.department_name
    FROM VISITS v
    JOIN HEALTH_WORKERS hw ON v.worker_id = hw.worker_id
    JOIN DEPARTMENTS d ON hw.department_id = d.department_id
    WHERE v.patient_id = p_patient_id
    ORDER BY v.visit_date DESC;
    
    RETURN visit_cursor;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in get_patient_history: ' || SQLERRM);
        RETURN NULL;
END get_patient_history;
/




-- Function to calculate total allowance for a specific role
CREATE OR REPLACE FUNCTION calculate_total_allowance(
    p_role_id IN NUMBER
) RETURN NUMBER
IS
    v_total_allowance NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Calculating total allowance for role ID: ' || p_role_id);
    
    -- Calculate total allowance for the role (only applicable allowances)
    SELECT NVL(SUM(allowance_amount), 0)
    INTO v_total_allowance
    FROM ALLOWANCES
    WHERE role_id = p_role_id
    AND is_applicable = 'Y';
    
    DBMS_OUTPUT.PUT_LINE('Total allowance calculated: $' || v_total_allowance);
    RETURN v_total_allowance;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No allowances found for role ID: ' || p_role_id);
        RETURN 0;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in calculate_total_allowance: ' || SQLERRM);
        RETURN -1; -- Return -1 to indicate error
END calculate_total_allowance;
/





-- Function to get formatted full name of a health worker
CREATE OR REPLACE FUNCTION get_worker_full_name(
    p_worker_id IN NUMBER
) RETURN VARCHAR2
IS
    v_full_name VARCHAR2(100);
    v_first_name HEALTH_WORKERS.first_name%TYPE;
    v_last_name HEALTH_WORKERS.last_name%TYPE;
    v_role_name ROLES.role_name%TYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Getting full name for worker ID: ' || p_worker_id);
    
    -- Fetch worker details and role
    SELECT 
        hw.first_name,
        hw.last_name,
        r.role_name
    INTO 
        v_first_name,
        v_last_name,
        v_role_name
    FROM HEALTH_WORKERS hw
    JOIN ROLES r ON hw.role_id = r.role_id
    WHERE hw.worker_id = p_worker_id;
    
    -- Format the full name with role
    v_full_name := v_first_name || ' ' || v_last_name || ' (' || v_role_name || ')';
    
    DBMS_OUTPUT.PUT_LINE('Formatted name: ' || v_full_name);
    RETURN v_full_name;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No health worker found with ID: ' || p_worker_id);
        RETURN 'Unknown Worker';
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('Multiple workers found with ID: ' || p_worker_id);
        RETURN 'Duplicate Worker ID';
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in get_worker_full_name: ' || SQLERRM);
        RETURN 'Error Retrieving Name';
END get_worker_full_name;
/





-- Test calculate_total_allowance function
DECLARE
    v_role_id NUMBER := 1; -- Doctor role
    v_role_name ROLES.role_name%TYPE;
    v_total_allowance NUMBER;
    i NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTING calculate_total_allowance FUNCTION ===');
    DBMS_OUTPUT.PUT_LINE('================================================');
    
    -- Test for multiple roles
    FOR i IN 1..5 LOOP
        BEGIN
            -- Get role name
            SELECT role_name INTO v_role_name FROM ROLES WHERE role_id = i;
            
            -- Call the function
            v_total_allowance := calculate_total_allowance(i);
            
            -- Display results
            DBMS_OUTPUT.PUT_LINE('Role: ' || v_role_name || ' (ID: ' || i || ')');
            DBMS_OUTPUT.PUT_LINE('Total Allowance: $' || v_total_allowance);
            DBMS_OUTPUT.PUT_LINE('---');
            
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('Role ID ' || i || ' not found.');
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error processing role ID ' || i || ': ' || SQLERRM);
        END;
    END LOOP;
    
    -- Test with invalid role ID
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Testing with invalid role ID:');
    v_total_allowance := calculate_total_allowance(999);
    DBMS_OUTPUT.PUT_LINE('Result for invalid role: $' || v_total_allowance);
    
END;
/





SET SERVEROUTPUT ON;

-- Test get_patient_history function
DECLARE
    visit_cursor SYS_REFCURSOR;
    v_visit_id VISITS.visit_id%TYPE;
    v_visit_date VISITS.visit_date%TYPE;
    v_diagnosis VISITS.diagnosis%TYPE;
    v_treatment VISITS.treatment%TYPE;
    v_notes VISITS.notes%TYPE;
    v_worker_name VARCHAR2(100);
    v_department VARCHAR2(100);
    v_patient_name VARCHAR2(100);
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTING get_patient_history FUNCTION ===');
    DBMS_OUTPUT.PUT_LINE('===========================================');
    
    -- Get patient name for context
    SELECT first_name || ' ' || last_name INTO v_patient_name
    FROM PATIENTS WHERE patient_id = 1001;
    
    DBMS_OUTPUT.PUT_LINE('Patient: ' || v_patient_name);
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Call the function
    visit_cursor := get_patient_history(1001);
    
    -- Process the cursor results
    DBMS_OUTPUT.PUT_LINE('VISIT HISTORY:');
    DBMS_OUTPUT.PUT_LINE('-------------');
    
    LOOP
        FETCH visit_cursor INTO v_visit_id, v_visit_date, v_diagnosis, v_treatment, v_notes, v_worker_name, v_department;
        EXIT WHEN visit_cursor%NOTFOUND;
        
        DBMS_OUTPUT.PUT_LINE('Visit ID: ' || v_visit_id);
        DBMS_OUTPUT.PUT_LINE('Date: ' || TO_CHAR(v_visit_date, 'DD-MON-YYYY'));
        DBMS_OUTPUT.PUT_LINE('Diagnosis: ' || v_diagnosis);
        DBMS_OUTPUT.PUT_LINE('Treatment: ' || v_treatment);
        DBMS_OUTPUT.PUT_LINE('Health Worker: ' || v_worker_name);
        DBMS_OUTPUT.PUT_LINE('Department: ' || v_department);
        IF v_notes IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('Notes: ' || v_notes);
        END IF;
        DBMS_OUTPUT.PUT_LINE('---');
    END LOOP;
    
    -- Close cursor
    CLOSE visit_cursor;
    
    DBMS_OUTPUT.PUT_LINE('End of visit history.');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in test: ' || SQLERRM);
        IF visit_cursor%ISOPEN THEN
            CLOSE visit_cursor;
        END IF;
END;
/





-- Test get_worker_full_name function
DECLARE
    v_worker_id NUMBER;
    v_full_name VARCHAR2(100);
    v_department_name DEPARTMENTS.department_name%TYPE;
    v_salary HEALTH_WORKERS.salary%TYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTING get_worker_full_name FUNCTION ===');
    DBMS_OUTPUT.PUT_LINE('===========================================');
    
    -- Test multiple workers
    FOR worker_rec IN (
        SELECT worker_id, department_id, salary 
        FROM HEALTH_WORKERS 
        WHERE ROWNUM <= 4
        ORDER BY worker_id
    ) 
    LOOP
        v_worker_id := worker_rec.worker_id;
        
        -- Get department name
        SELECT department_name INTO v_department_name
        FROM DEPARTMENTS 
        WHERE department_id = worker_rec.department_id;
        
        -- Call the function
        v_full_name := get_worker_full_name(v_worker_id);
        
        -- Display results
        DBMS_OUTPUT.PUT_LINE('Worker ID: ' || v_worker_id);
        DBMS_OUTPUT.PUT_LINE('Formatted Name: ' || v_full_name);
        DBMS_OUTPUT.PUT_LINE('Department: ' || v_department_name);
        DBMS_OUTPUT.PUT_LINE('Salary: $' || worker_rec.salary);
        DBMS_OUTPUT.PUT_LINE('---');
    END LOOP;
    
    -- Test with invalid worker ID
    DBMS_OUTPUT.PUT_LINE('Testing with invalid worker ID:');
    v_full_name := get_worker_full_name(999);
    DBMS_OUTPUT.PUT_LINE('Result: ' || v_full_name);
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in test: ' || SQLERRM);
END;
/





-- Procedure to add a new patient visit
CREATE OR REPLACE PROCEDURE add_new_visit(
    p_patient_id IN NUMBER,
    p_worker_id IN NUMBER,
    p_diagnosis IN VARCHAR2,
    p_treatment IN VARCHAR2 DEFAULT NULL,
    p_notes IN VARCHAR2 DEFAULT NULL
)
IS
    v_next_visit_id VISITS.visit_id%TYPE;
    v_patient_name PATIENTS.first_name%TYPE;
    v_worker_name HEALTH_WORKERS.first_name%TYPE;
    v_department_name DEPARTMENTS.department_name%TYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== ADDING NEW VISIT ===');
    
    -- Validate patient exists
    BEGIN
        SELECT first_name || ' ' || last_name INTO v_patient_name
        FROM PATIENTS WHERE patient_id = p_patient_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Patient ID ' || p_patient_id || ' does not exist.');
    END;
    
    -- Validate health worker exists and get details
    BEGIN
        SELECT hw.first_name || ' ' || hw.last_name, d.department_name
        INTO v_worker_name, v_department_name
        FROM HEALTH_WORKERS hw
        JOIN DEPARTMENTS d ON hw.department_id = d.department_id
        WHERE hw.worker_id = p_worker_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'Health worker ID ' || p_worker_id || ' does not exist.');
    END;
    
    -- Get next visit ID (simple sequence simulation)
    SELECT NVL(MAX(visit_id), 0) + 1 INTO v_next_visit_id FROM VISITS;
    
    -- Insert the new visit
    INSERT INTO VISITS (
        visit_id, patient_id, worker_id, visit_date, 
        diagnosis, treatment, notes
    ) VALUES (
        v_next_visit_id, p_patient_id, p_worker_id, SYSDATE,
        p_diagnosis, p_treatment, p_notes
    );
    
    -- Commit the transaction
    COMMIT;
    
    -- Display success message
    DBMS_OUTPUT.PUT_LINE('SUCCESS: New visit added successfully!');
    DBMS_OUTPUT.PUT_LINE('Visit ID: ' || v_next_visit_id);
    DBMS_OUTPUT.PUT_LINE('Patient: ' || v_patient_name);
    DBMS_OUTPUT.PUT_LINE('Health Worker: ' || v_worker_name || ' (' || v_department_name || ')');
    DBMS_OUTPUT.PUT_LINE('Diagnosis: ' || p_diagnosis);
    DBMS_OUTPUT.PUT_LINE('Treatment: ' || NVL(p_treatment, 'Not specified'));
    DBMS_OUTPUT.PUT_LINE('Visit Date: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI'));
    
EXCEPTION
    WHEN OTHERS THEN
        -- Rollback in case of error
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: Failed to add new visit - ' || SQLERRM);
        RAISE;
END add_new_visit;
/






-- Procedure to update health worker salary with validation
CREATE OR REPLACE PROCEDURE update_worker_salary(
    p_worker_id IN NUMBER,
    p_new_salary IN NUMBER
)
IS
    v_old_salary HEALTH_WORKERS.salary%TYPE;
    v_worker_name VARCHAR2(100);
    v_role_name ROLES.role_name%TYPE;
    v_department_name DEPARTMENTS.department_name%TYPE;
    v_salary_change NUMBER;
    v_percentage_change NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== UPDATING WORKER SALARY ===');
    
    -- Validate input parameters
    IF p_new_salary IS NULL OR p_new_salary < 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Invalid salary amount: ' || p_new_salary);
    END IF;
    
    -- Get current worker details
    BEGIN
        SELECT 
            hw.first_name || ' ' || hw.last_name,
            hw.salary,
            r.role_name,
            d.department_name
        INTO 
            v_worker_name,
            v_old_salary,
            v_role_name,
            v_department_name
        FROM HEALTH_WORKERS hw
        JOIN ROLES r ON hw.role_id = r.role_id
        JOIN DEPARTMENTS d ON hw.department_id = d.department_id
        WHERE hw.worker_id = p_worker_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20004, 'Health worker ID ' || p_worker_id || ' does not exist.');
    END;
    
    -- Calculate changes
    v_salary_change := p_new_salary - v_old_salary;
    v_percentage_change := ROUND((v_salary_change / v_old_salary) * 100, 2);
    
    -- Update the salary
    UPDATE HEALTH_WORKERS 
    SET salary = p_new_salary
    WHERE worker_id = p_worker_id;
    
    -- Commit the transaction
    COMMIT;
    
    -- Display update details
    DBMS_OUTPUT.PUT_LINE('SUCCESS: Salary updated successfully!');
    DBMS_OUTPUT.PUT_LINE('Worker: ' || v_worker_name);
    DBMS_OUTPUT.PUT_LINE('Role: ' || v_role_name);
    DBMS_OUTPUT.PUT_LINE('Department: ' || v_department_name);
    DBMS_OUTPUT.PUT_LINE('Old Salary: $' || v_old_salary);
    DBMS_OUTPUT.PUT_LINE('New Salary: $' || p_new_salary);
    DBMS_OUTPUT.PUT_LINE('Salary Change: $' || v_salary_change);
    DBMS_OUTPUT.PUT_LINE('Percentage Change: ' || v_percentage_change || '%');
    
    -- Additional business logic based on salary change
    IF v_percentage_change > 20 THEN
        DBMS_OUTPUT.PUT_LINE('NOTICE: Large salary increase detected (>20%)');
    ELSIF v_percentage_change < -10 THEN
        DBMS_OUTPUT.PUT_LINE('NOTICE: Significant salary decrease detected (<-10%)');
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: Failed to update salary - ' || SQLERRM);
        RAISE;
END update_worker_salary;
/





-- Procedure to generate comprehensive health report for a department
CREATE OR REPLACE PROCEDURE generate_health_report(
    p_department_id IN NUMBER
)
IS
    v_department_name DEPARTMENTS.department_name%TYPE;
    v_worker_count NUMBER;
    v_patient_count NUMBER;
    v_visit_count NUMBER;
    v_avg_salary NUMBER;
    v_total_allowance NUMBER;
    
    -- Cursor for department workers
    CURSOR c_workers IS
        SELECT 
            worker_id,
            first_name || ' ' || last_name AS full_name,
            salary,
            hire_date
        FROM HEALTH_WORKERS
        WHERE department_id = p_department_id
        ORDER BY salary DESC;
    
    -- Cursor for recent visits in department
    CURSOR c_recent_visits IS
        SELECT 
            v.visit_date,
            p.first_name || ' ' || p.last_name AS patient_name,
            v.diagnosis,
            hw.first_name || ' ' || hw.last_name AS worker_name
        FROM VISITS v
        JOIN HEALTH_WORKERS hw ON v.worker_id = hw.worker_id
        JOIN PATIENTS p ON v.patient_id = p.patient_id
        WHERE hw.department_id = p_department_id
        AND v.visit_date >= ADD_MONTHS(SYSDATE, -3) -- Last 3 months
        ORDER BY v.visit_date DESC;
    
    -- Cursor for common diagnoses
    CURSOR c_common_diagnoses IS
        SELECT 
            diagnosis,
            COUNT(*) as frequency
        FROM VISITS v
        JOIN HEALTH_WORKERS hw ON v.worker_id = hw.worker_id
        WHERE hw.department_id = p_department_id
        AND diagnosis IS NOT NULL
        GROUP BY diagnosis
        ORDER BY frequency DESC;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== GENERATING HEALTH DEPARTMENT REPORT ===');
    DBMS_OUTPUT.PUT_LINE('==========================================');
    
    -- Get department name
    BEGIN
        SELECT department_name INTO v_department_name
        FROM DEPARTMENTS 
        WHERE department_id = p_department_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20005, 'Department ID ' || p_department_id || ' does not exist.');
    END;
    
    DBMS_OUTPUT.PUT_LINE('DEPARTMENT: ' || v_department_name);
    DBMS_OUTPUT.PUT_LINE('Report Date: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI'));
    DBMS_OUTPUT.PUT_LINE('=' || RPAD('=', 50, '='));
    
    -- Get department statistics
    SELECT 
        COUNT(DISTINCT hw.worker_id),
        COUNT(DISTINCT v.patient_id),
        COUNT(v.visit_id),
        AVG(hw.salary)
    INTO 
        v_worker_count,
        v_patient_count,
        v_visit_count,
        v_avg_salary
    FROM HEALTH_WORKERS hw
    LEFT JOIN VISITS v ON hw.worker_id = v.worker_id
    WHERE hw.department_id = p_department_id;
    
    -- Calculate total allowance for the department
    SELECT NVL(SUM(a.allowance_amount), 0)
    INTO v_total_allowance
    FROM ALLOWANCES a
    JOIN HEALTH_WORKERS hw ON a.role_id = hw.role_id
    WHERE hw.department_id = p_department_id
    AND a.is_applicable = 'Y';
    
    -- Display department summary
    DBMS_OUTPUT.PUT_LINE('DEPARTMENT SUMMARY:');
    DBMS_OUTPUT.PUT_LINE('  Total Health Workers: ' || v_worker_count);
    DBMS_OUTPUT.PUT_LINE('  Total Patients Served: ' || v_patient_count);
    DBMS_OUTPUT.PUT_LINE('  Total Visits: ' || v_visit_count);
    DBMS_OUTPUT.PUT_LINE('  Average Salary: $' || ROUND(v_avg_salary, 2));
    DBMS_OUTPUT.PUT_LINE('  Total Allowances: $' || v_total_allowance);
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Display health workers
    DBMS_OUTPUT.PUT_LINE('HEALTH WORKERS IN DEPARTMENT:');
    DBMS_OUTPUT.PUT_LINE('  ' || RPAD('Name', 25) || RPAD('Salary', 10) || 'Experience');
    DBMS_OUTPUT.PUT_LINE('  ' || RPAD('-', 25, '-') || RPAD('-', 10, '-') || '----------');
    
    FOR worker_rec IN c_workers LOOP
        DBMS_OUTPUT.PUT_LINE('  ' || 
            RPAD(worker_rec.full_name, 25) || 
            RPAD('$' || worker_rec.salary, 10) ||
            FLOOR(MONTHS_BETWEEN(SYSDATE, worker_rec.hire_date)/12) || ' years'
        );
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Display recent visits
    DBMS_OUTPUT.PUT_LINE('RECENT VISITS (Last 3 Months):');
    DBMS_OUTPUT.PUT_LINE('  ' || RPAD('Date', 12) || RPAD('Patient', 20) || RPAD('Health Worker', 20) || 'Diagnosis');
    DBMS_OUTPUT.PUT_LINE('  ' || RPAD('-', 12, '-') || RPAD('-', 20, '-') || RPAD('-', 20, '-') || '--------');
    
    FOR visit_rec IN c_recent_visits LOOP
        DBMS_OUTPUT.PUT_LINE('  ' || 
            RPAD(TO_CHAR(visit_rec.visit_date, 'DD-MON'), 12) ||
            RPAD(visit_rec.patient_name, 20) ||
            RPAD(visit_rec.worker_name, 20) ||
            visit_rec.diagnosis
        );
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Display common diagnoses
    DBMS_OUTPUT.PUT_LINE('COMMON DIAGNOSES:');
    DBMS_OUTPUT.PUT_LINE('  ' || RPAD('Diagnosis', 25) || 'Frequency');
    DBMS_OUTPUT.PUT_LINE('  ' || RPAD('-', 25, '-') || '---------');
    
    FOR diagnosis_rec IN c_common_diagnoses LOOP
        DBMS_OUTPUT.PUT_LINE('  ' || 
            RPAD(diagnosis_rec.diagnosis, 25) || 
            diagnosis_rec.frequency
        );
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== REPORT GENERATION COMPLETE ===');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Failed to generate report - ' || SQLERRM);
        RAISE;
END generate_health_report;
/




SET SERVEROUTPUT ON;

-- Test add_new_visit procedure
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTING add_new_visit PROCEDURE ===');
    DBMS_OUTPUT.PUT_LINE('=====================================');
    
    -- Test case 1: Normal visit
    DBMS_OUTPUT.PUT_LINE('Test 1: Adding normal visit');
    add_new_visit(
        p_patient_id => 1002,
        p_worker_id => 103,
        p_diagnosis => 'Common Cold',
        p_treatment => 'Rest and hydration',
        p_notes => 'Patient should return if symptoms persist'
    );
    
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Test case 2: Visit with minimal information
    DBMS_OUTPUT.PUT_LINE('Test 2: Adding visit with minimal info');
    add_new_visit(
        p_patient_id => 1003,
        p_worker_id => 101,
        p_diagnosis => 'Routine Checkup'
    );
    
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Test case 3: Invalid patient (should fail)
    DBMS_OUTPUT.PUT_LINE('Test 3: Testing with invalid patient (should fail)');
    BEGIN
        add_new_visit(
            p_patient_id => 9999,
            p_worker_id => 101,
            p_diagnosis => 'Test Diagnosis'
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
    
END;
/




-- Test update_worker_salary procedure
DECLARE
    v_worker_id NUMBER := 102;
    v_current_salary NUMBER;
    v_new_salary NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTING update_worker_salary PROCEDURE ===');
    DBMS_OUTPUT.PUT_LINE('============================================');
    
    -- Get current salary
    SELECT salary INTO v_current_salary 
    FROM HEALTH_WORKERS 
    WHERE worker_id = v_worker_id;
    
    DBMS_OUTPUT.PUT_LINE('Current salary: $' || v_current_salary);
    
    -- Test case 1: Reasonable salary increase
    v_new_salary := v_current_salary * 1.10; -- 10% increase
    DBMS_OUTPUT.PUT_LINE('Test 1: 10% salary increase');
    update_worker_salary(v_worker_id, v_new_salary);
    
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Test case 2: Large increase (should trigger notice)
    v_new_salary := v_current_salary * 1.25; -- 25% increase
    DBMS_OUTPUT.PUT_LINE('Test 2: 25% salary increase (should trigger notice)');
    update_worker_salary(v_worker_id, v_new_salary);
    
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Test case 3: Invalid salary (should fail)
    DBMS_OUTPUT.PUT_LINE('Test 3: Testing with negative salary (should fail)');
    BEGIN
        update_worker_salary(v_worker_id, -1000);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
    
    -- Rollback changes for testing (so we can run multiple times)
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Note: All changes rolled back for testing purposes.');
    
END;
/




-- Test generate_health_report procedure
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTING generate_health_report PROCEDURE ===');
    DBMS_OUTPUT.PUT_LINE('==============================================');
    
    -- Test case 1: Pediatrics department (ID 1)
    DBMS_OUTPUT.PUT_LINE('Test 1: Pediatrics Department Report');
    generate_health_report(1);
    
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '=' || RPAD('=', 60, '=') || CHR(10));
    
    -- Test case 2: General Medicine department (ID 2)
    DBMS_OUTPUT.PUT_LINE('Test 2: General Medicine Department Report');
    generate_health_report(2);
    
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '=' || RPAD('=', 60, '=') || CHR(10));
    
    -- Test case 3: Invalid department (should fail)
    DBMS_OUTPUT.PUT_LINE('Test 3: Testing with invalid department (should fail)');
    BEGIN
        generate_health_report(999);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
    
END;
/







SET SERVEROUTPUT ON;

-- Explicit cursor to list all patients visited in a given month
DECLARE
    -- Declare explicit cursor for patients visited in a specific month
    CURSOR c_patients_by_month IS
        SELECT DISTINCT 
            p.patient_id,
            p.first_name || ' ' || p.last_name AS patient_name,
            p.gender,
            p.contact,
            COUNT(v.visit_id) AS visit_count
        FROM PATIENTS p
        JOIN VISITS v ON p.patient_id = v.patient_id
        WHERE EXTRACT(YEAR FROM v.visit_date) = 2024
          AND EXTRACT(MONTH FROM v.visit_date) = 2  -- February 2024
        GROUP BY p.patient_id, p.first_name, p.last_name, p.gender, p.contact
        ORDER BY visit_count DESC;
    
    -- Record variable to hold cursor data
    patient_rec c_patients_by_month%ROWTYPE;
    
    -- Counter variables
    v_total_patients NUMBER := 0;
    v_total_visits NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== EXPLICIT CURSOR: PATIENTS VISITED IN FEBRUARY 2024 ===');
    DBMS_OUTPUT.PUT_LINE('========================================================');
    
    -- Open the cursor
    OPEN c_patients_by_month;
    
    -- Display header
    DBMS_OUTPUT.PUT_LINE(RPAD('Patient Name', 20) || RPAD('Gender', 8) || 
                        RPAD('Contact', 12) || 'Visits');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 20, '-') || RPAD('-', 8, '-') || 
                        RPAD('-', 12, '-') || '------');
    
    -- Fetch and process each row
    LOOP
        FETCH c_patients_by_month INTO patient_rec;
        EXIT WHEN c_patients_by_month%NOTFOUND;
        
        -- Process the current row
        v_total_patients := v_total_patients + 1;
        v_total_visits := v_total_visits + patient_rec.visit_count;
        
        -- Display patient information
        DBMS_OUTPUT.PUT_LINE(
            RPAD(patient_rec.patient_name, 20) ||
            RPAD(patient_rec.gender, 8) ||
            RPAD(patient_rec.contact, 12) ||
            patient_rec.visit_count
        );
    END LOOP;
    
    -- Close the cursor
    CLOSE c_patients_by_month;
    
    -- Display summary using cursor attributes
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('SUMMARY:');
    DBMS_OUTPUT.PUT_LINE('  Total Patients: ' || v_total_patients);
    DBMS_OUTPUT.PUT_LINE('  Total Visits: ' || v_total_visits);
    
    -- Demonstrate cursor attributes (though cursor is closed now)
    IF NOT c_patients_by_month%ISOPEN THEN
        DBMS_OUTPUT.PUT_LINE('  Cursor Status: Closed');
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        -- Ensure cursor is closed in case of error
        IF c_patients_by_month%ISOPEN THEN
            CLOSE c_patients_by_month;
        END IF;
END;
/







-- Parameterized cursor to fetch workers by department with detailed information
DECLARE
    -- Declare parameterized cursor
    CURSOR c_workers_by_dept (p_dept_id NUMBER, p_min_salary NUMBER DEFAULT 0) IS
        SELECT 
            hw.worker_id,
            hw.first_name || ' ' || hw.last_name AS worker_name,
            r.role_name,
            hw.salary,
            hw.bonus,
            hw.hire_date,
            d.department_name,
            (hw.salary + NVL(hw.bonus, 0)) AS total_compensation
        FROM HEALTH_WORKERS hw
        JOIN ROLES r ON hw.role_id = r.role_id
        JOIN DEPARTMENTS d ON hw.department_id = d.department_id
        WHERE hw.department_id = p_dept_id
          AND hw.salary >= p_min_salary
        ORDER BY total_compensation DESC;
    
    -- Record variable for cursor
    worker_rec c_workers_by_dept%ROWTYPE;
    
    -- Local variables for calculations
    v_avg_salary NUMBER;
    v_high_earner_count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== PARAMETERIZED CURSOR: WORKERS BY DEPARTMENT ===');
    DBMS_OUTPUT.PUT_LINE('==================================================');
    
    -- Test with different departments and salary filters
    
    -- Test 1: Pediatrics department (ID 1) with no salary filter
    DBMS_OUTPUT.PUT_LINE('TEST 1: PEDIATRICS DEPARTMENT (All Salaries)');
    DBMS_OUTPUT.PUT_LINE('---------------------------------------------');
    
    OPEN c_workers_by_dept(p_dept_id => 1, p_min_salary => 0);
    
    LOOP
        FETCH c_workers_by_dept INTO worker_rec;
        EXIT WHEN c_workers_by_dept%NOTFOUND;
        
        DBMS_OUTPUT.PUT_LINE('Name: ' || worker_rec.worker_name);
        DBMS_OUTPUT.PUT_LINE('  Role: ' || worker_rec.role_name);
        DBMS_OUTPUT.PUT_LINE('  Salary: $' || worker_rec.salary);
        DBMS_OUTPUT.PUT_LINE('  Bonus: $' || NVL(worker_rec.bonus, 0));
        DBMS_OUTPUT.PUT_LINE('  Total: $' || worker_rec.total_compensation);
        DBMS_OUTPUT.PUT_LINE('  Experience: ' || 
                           FLOOR(MONTHS_BETWEEN(SYSDATE, worker_rec.hire_date)/12) || ' years');
        
        -- Count high earners
        IF worker_rec.total_compensation > 50000 THEN
            v_high_earner_count := v_high_earner_count + 1;
        END IF;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('Workers found: ' || c_workers_by_dept%ROWCOUNT);
    DBMS_OUTPUT.PUT_LINE('High earners (>$50K): ' || v_high_earner_count);
    CLOSE c_workers_by_dept;
    
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Test 2: Community Outreach with salary filter
    DBMS_OUTPUT.PUT_LINE('TEST 2: COMMUNITY OUTREACH (Salary >= $30,000)');
    DBMS_OUTPUT.PUT_LINE('-----------------------------------------------');
    
    v_high_earner_count := 0;  -- Reset counter
    
    OPEN c_workers_by_dept(p_dept_id => 5, p_min_salary => 30000);
    
    LOOP
        FETCH c_workers_by_dept INTO worker_rec;
        EXIT WHEN c_workers_by_dept%NOTFOUND;
        
        DBMS_OUTPUT.PUT_LINE('Name: ' || worker_rec.worker_name);
        DBMS_OUTPUT.PUT_LINE('  Role: ' || worker_rec.role_name);
        DBMS_OUTPUT.PUT_LINE('  Salary: $' || worker_rec.salary);
        DBMS_OUTPUT.PUT_LINE('  Department: ' || worker_rec.department_name);
        
        IF worker_rec.total_compensation > 40000 THEN
            v_high_earner_count := v_high_earner_count + 1;
        END IF;
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('Workers found: ' || c_workers_by_dept%ROWCOUNT);
    DBMS_OUTPUT.PUT_LINE('High earners (>$40K): ' || v_high_earner_count);
    CLOSE c_workers_by_dept;
    
    -- Test 3: Department with no workers (should show no results)
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('TEST 3: NON-EXISTENT DEPARTMENT (Should show no results)');
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------');
    
    OPEN c_workers_by_dept(p_dept_id => 999, p_min_salary => 0);
    
    IF c_workers_by_dept%NOTFOUND THEN
        DBMS_OUTPUT.PUT_LINE('No workers found in specified department.');
    ELSE
        LOOP
            FETCH c_workers_by_dept INTO worker_rec;
            EXIT WHEN c_workers_by_dept%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE('Name: ' || worker_rec.worker_name);
        END LOOP;
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('Workers found: ' || c_workers_by_dept%ROWCOUNT);
    CLOSE c_workers_by_dept;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        -- Close all cursors that might be open
        IF c_workers_by_dept%ISOPEN THEN
            CLOSE c_workers_by_dept;
        END IF;
END;
/





-- Cursor FOR loop to display comprehensive health worker details
DECLARE
    -- Counter for statistics
    v_total_workers NUMBER := 0;
    v_total_salary NUMBER := 0;
    v_doctor_count NUMBER := 0;
    v_nurse_count NUMBER := 0;
    v_other_count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== CURSOR FOR LOOP: COMPREHENSIVE HEALTH WORKER DETAILS ===');
    DBMS_OUTPUT.PUT_LINE('==========================================================');
    
    -- Cursor FOR loop (automatically opens, fetches, and closes cursor)
    FOR worker_rec IN (
        SELECT 
            hw.worker_id,
            hw.first_name || ' ' || hw.last_name AS full_name,
            r.role_name,
            d.department_name,
            hw.salary,
            hw.bonus,
            hw.hire_date,
            hw.email,
            (hw.salary + NVL(hw.bonus, 0)) AS total_compensation,
            FLOOR(MONTHS_BETWEEN(SYSDATE, hw.hire_date)/12) AS years_experience,
            -- Categorize experience levels
            CASE 
                WHEN MONTHS_BETWEEN(SYSDATE, hw.hire_date)/12 >= 10 THEN 'Senior'
                WHEN MONTHS_BETWEEN(SYSDATE, hw.hire_date)/12 >= 5 THEN 'Mid-Level'
                ELSE 'Junior'
            END AS experience_level
        FROM HEALTH_WORKERS hw
        JOIN ROLES r ON hw.role_id = r.role_id
        JOIN DEPARTMENTS d ON hw.department_id = d.department_id
        ORDER BY d.department_name, total_compensation DESC
    ) 
    LOOP
        v_total_workers := v_total_workers + 1;
        v_total_salary := v_total_salary + worker_rec.salary;
        
        -- Count by role type
        IF worker_rec.role_name = 'Doctor' THEN
            v_doctor_count := v_doctor_count + 1;
        ELSIF worker_rec.role_name = 'Nurse' THEN
            v_nurse_count := v_nurse_count + 1;
        ELSE
            v_other_count := v_other_count + 1;
        END IF;
        
        -- Display worker information with formatting
        DBMS_OUTPUT.PUT_LINE('WORKER #' || v_total_workers || ':');
        DBMS_OUTPUT.PUT_LINE('  Name: ' || worker_rec.full_name);
        DBMS_OUTPUT.PUT_LINE('  Role: ' || worker_rec.role_name || ' (' || worker_rec.experience_level || ')');
        DBMS_OUTPUT.PUT_LINE('  Department: ' || worker_rec.department_name);
        DBMS_OUTPUT.PUT_LINE('  Contact: ' || worker_rec.email);
        DBMS_OUTPUT.PUT_LINE('  Salary: $' || worker_rec.salary);
        DBMS_OUTPUT.PUT_LINE('  Bonus: $' || NVL(worker_rec.bonus, 0));
        DBMS_OUTPUT.PUT_LINE('  Total Compensation: $' || worker_rec.total_compensation);
        DBMS_OUTPUT.PUT_LINE('  Experience: ' || worker_rec.years_experience || ' years');
        DBMS_OUTPUT.PUT_LINE('  Hire Date: ' || TO_CHAR(worker_rec.hire_date, 'DD-MON-YYYY'));
        
        -- Add performance indicators based on salary and experience
        IF worker_rec.years_experience > 5 AND worker_rec.salary < 40000 THEN
            DBMS_OUTPUT.PUT_LINE('  ** NOTICE: Consider salary review - experienced worker with below-average pay');
        ELSIF worker_rec.years_experience < 2 AND worker_rec.salary > 50000 THEN
            DBMS_OUTPUT.PUT_LINE('  ** NOTICE: High salary for junior position');
        END IF;
        
        DBMS_OUTPUT.PUT_LINE('---');
    END LOOP;
    
    -- Display comprehensive summary
    DBMS_OUTPUT.PUT_LINE('=== WORKFORCE SUMMARY ===');
    DBMS_OUTPUT.PUT_LINE('Total Health Workers: ' || v_total_workers);
    DBMS_OUTPUT.PUT_LINE('Doctors: ' || v_doctor_count);
    DBMS_OUTPUT.PUT_LINE('Nurses: ' || v_nurse_count);
    DBMS_OUTPUT.PUT_LINE('Other Roles: ' || v_other_count);
    DBMS_OUTPUT.PUT_LINE('Total Salary Expenditure: $' || v_total_salary);
    DBMS_OUTPUT.PUT_LINE('Average Salary: $' || ROUND(v_total_salary / NULLIF(v_total_workers, 0), 2));
    
    -- Additional analysis
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('WORKFORCE DISTRIBUTION:');
    DBMS_OUTPUT.PUT_LINE('  Doctors: ' || ROUND((v_doctor_count / v_total_workers) * 100, 1) || '%');
    DBMS_OUTPUT.PUT_LINE('  Nurses: ' || ROUND((v_nurse_count / v_total_workers) * 100, 1) || '%');
    DBMS_OUTPUT.PUT_LINE('  Other Staff: ' || ROUND((v_other_count / v_total_workers) * 100, 1) || '%');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in cursor FOR loop: ' || SQLERRM);
END;
/






-- Package Specification: Defines the public interface
CREATE OR REPLACE PACKAGE HEALTH_MGMT AS
    -- =============================================
    -- PUBLIC CONSTANTS
    -- =============================================
    MIN_SALARY CONSTANT NUMBER := 20000;
    MAX_SALARY CONSTANT NUMBER := 150000;
    
    -- =============================================
    -- PUBLIC EXCEPTIONS
    -- =============================================
    invalid_salary_exception EXCEPTION;
    PRAGMA EXCEPTION_INIT(invalid_salary_exception, -20010);
    
    duplicate_worker_exception EXCEPTION;
    PRAGMA EXCEPTION_INIT(duplicate_worker_exception, -20011);
    
    -- =============================================
    -- PUBLIC TYPES
    -- =============================================
    TYPE worker_summary_rec IS RECORD (
        worker_id HEALTH_WORKERS.worker_id%TYPE,
        full_name VARCHAR2(100),
        role_name ROLES.role_name%TYPE,
        department_name DEPARTMENTS.department_name%TYPE,
        salary HEALTH_WORKERS.salary%TYPE,
        total_compensation NUMBER
    );
    
    TYPE worker_summary_table IS TABLE OF worker_summary_rec;
    
    TYPE visit_history_rec IS RECORD (
        visit_id VISITS.visit_id%TYPE,
        visit_date VISITS.visit_date%TYPE,
        diagnosis VISITS.diagnosis%TYPE,
        health_worker_name VARCHAR2(100),
        department_name VARCHAR2(100)
    );
    
    TYPE visit_history_table IS TABLE OF visit_history_rec;
    
    -- =============================================
    -- PATIENT MANAGEMENT FUNCTIONS/PROCEDURES
    -- =============================================
    
    -- Function to get patient visit history
    FUNCTION get_patient_history(
        p_patient_id IN NUMBER
    ) RETURN SYS_REFCURSOR;
    
    -- Function to get patient full name
    FUNCTION get_patient_full_name(
        p_patient_id IN NUMBER
    ) RETURN VARCHAR2;
    
    -- Procedure to add new patient visit
    PROCEDURE add_new_visit(
        p_patient_id IN NUMBER,
        p_worker_id IN NUMBER,
        p_diagnosis IN VARCHAR2,
        p_treatment IN VARCHAR2 DEFAULT NULL,
        p_notes IN VARCHAR2 DEFAULT NULL
    );
    
    -- Function to get patient statistics
    FUNCTION get_patient_statistics(
        p_patient_id IN NUMBER
    ) RETURN VARCHAR2;
    
    -- =============================================
    -- HEALTH WORKER MANAGEMENT FUNCTIONS/PROCEDURES
    -- =============================================
    
    -- Function to get worker full name with role
    FUNCTION get_worker_full_name(
        p_worker_id IN NUMBER
    ) RETURN VARCHAR2;
    
    -- Procedure to update worker salary
    PROCEDURE update_worker_salary(
        p_worker_id IN NUMBER,
        p_new_salary IN NUMBER
    );
    
    -- Function to calculate total compensation
    FUNCTION calculate_total_compensation(
        p_worker_id IN NUMBER
    ) RETURN NUMBER;
    
    -- Function to get workers by department
    FUNCTION get_workers_by_department(
        p_department_id IN NUMBER
    ) RETURN worker_summary_table;
    
    -- Procedure to add new health worker
    PROCEDURE add_health_worker(
        p_first_name IN VARCHAR2,
        p_last_name IN VARCHAR2,
        p_email IN VARCHAR2,
        p_role_id IN NUMBER,
        p_department_id IN NUMBER,
        p_salary IN NUMBER,
        p_phone_number IN VARCHAR2 DEFAULT NULL
    );
    
    -- =============================================
    -- DEPARTMENT MANAGEMENT FUNCTIONS/PROCEDURES
    -- =============================================
    
    -- Procedure to generate department health report
    PROCEDURE generate_health_report(
        p_department_id IN NUMBER
    );
    
    -- Function to calculate total allowance for role
    FUNCTION calculate_total_allowance(
        p_role_id IN NUMBER
    ) RETURN NUMBER;
    
    -- Function to get department statistics
    FUNCTION get_department_statistics(
        p_department_id IN NUMBER
    ) RETURN VARCHAR2;
    
    -- =============================================
    -- SYSTEM UTILITIES
    -- =============================================
    
    -- Function to validate email format
    FUNCTION is_valid_email(
        p_email IN VARCHAR2
    ) RETURN BOOLEAN;
    
    -- Procedure to display system information
    PROCEDURE display_system_info;
    
    -- Function to get package version
    FUNCTION get_version RETURN VARCHAR2;
    
END HEALTH_MGMT;
/




