
set serveroutput on;
-- drop table hr.test_cases;

-- creating a table to hold the input test cases numbers
create table hr.test_cases (
  idx number(4) primary key,
  in_n number(12)
);

-- select * from hr.test_cases;

-- drop sequence hr.tc_idx_seq  

-- in order to fave full control over the ordering of the numbers present in the file 
-- let's create a sequence that will populate the PK (idx) column
-- very important: first line of the input file gives the number of tests so in the input files this is 100 

create sequence hr.tc_idx_seq  
minvalue 0
start with 0
increment by 1;

-- creating support for loading the input file and reading it later
create or replace directory MY_DIR AS 'D:\CountSheep'; 
-- we are just playing here
grant read on directory MY_DIR TO PUBLIC;

-- clean up table (added for several iterations of debugging script)
truncate table hr.test_cases;

-- 1. Read input file and insert its content into the working table
declare
  in_n number(12);
  input_file UTL_FILE.FILE_TYPE; 
begin
  -- storin' the file
  input_file := UTL_FILE.FOPEN('MY_DIR','A-small-practice.in','R'); 
  loop
    begin
      UTL_FILE.GET_LINE(input_file,in_n); 
      -- make sure tests table is clean
      insert into HR.TEST_CASES(idx, in_n) values (hr.tc_idx_seq.nextval, in_n);
      
      exception when No_Data_Found then exit; 
    end;
  end loop;

  -- closing the file from memory, after a quick check
  if UTL_FILE.IS_OPEN(input_file) then
    dbms_output.put_line('File is Open! Closing it soon..');
  end if;

  UTL_FILE.FCLOSE(input_file); 
end; 
/
-- set serveroutput off;
-- select * from hr.test_cases;
-- 2. Get number of tests from the first line of the input file.

declare
  tests_number number; 
  cursor c_numbers is 
        select idx, in_n 
        from hr.test_cases
        where idx != (select min(idx) from hr.test_cases);    
  idx number := 0;      
  crt_idx number;
  curr_number number; 
  last_seen_number number(20);
  zero2nine varchar2(10);
  output_file UTL_FILE.FILE_TYPE;
  output_filename varchar2(30) := 'A-small-practice.out';
  
begin
  DBMS_OUTPUT.ENABLE (buffer_size => NULL);
  output_file := UTL_FILE.FOPEN('MY_DIR', output_filename, 'W');

  select tc.in_n into tests_number
  from hr.test_cases tc
  where tc.idx = (select min(idx) from hr.test_cases);
  
  -- check if T (number of test cases is in the renge 1 <= T <= 100)
  if (tests_number < 0 or tests_number > 100) then  
    dbms_output.put_line('Number of test cases (' || to_char(tests_number) || ') is not in the required range 1 ? T ? 100. Exiting.. ');
    return;
  end if;
  dbms_output.put_line('Number of tests in the input file is: ' || to_char(tests_number));

  open c_numbers;
  loop   
    fetch c_numbers into crt_idx, curr_number;
    exit when c_numbers%notfound;
      -- loop for N, N*2, N*3.. and check if all numbers are there
      zero2nine := '0123456789'; -- order of string elements not relly important
      idx :=  idx + 1;
      --dbms_output.put_line(curr_number);
      for i in 1..99999
      loop
        -- dbms_output.put_line('i is :' || to_char(i)); 
        last_seen_number := curr_number*i;
        -- dbms_output.put_line('last_seen_number is :' || to_char(last_seen_number));
        -- if the input number is either zero or last entry in the file then exit --> INSOMNIA
        if (coalesce(last_seen_number, 0) = 0) then
          --dbms_output.put_line('Case #' || to_char(idx) || ': INSOMNIA');
          utl_file.put_line(output_file, 'Case #' || to_char(idx) || ': INSOMNIA');
          exit;
        end if;  
        
        for j in 0..9 
        loop
          -- dbms_output.put_line('zero2nine is :' || to_char(zero2nine)); 
          -- if the current digit is in the zero2nine variable then trim this
          if (instr(to_char(last_seen_number), to_char(j)) > 0) then
            zero2nine := REPLACE(zero2nine,to_char(j),'');
          end if;
        end loop;
        if (length(zero2nine) is null) then
          --dbms_output.put_line('Case #' || to_char(idx) || ': ' || to_char(last_seen_number));
          utl_file.put_line(output_file, 'Case #' || to_char(idx) || ': ' || to_char(last_seen_number));
          exit;
        end if;
      end loop;    
  end loop;
  close c_numbers;
  utl_file.fclose(output_file);
end;
/
