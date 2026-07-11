-- CREATING THE DATABASE -- 
CREATE DATABASE manufacturing_project;

-- CREATING THE TABLE--  
USE manufacturing_project;
CREATE TABLE manufacturing_data (
event_id VARCHAR(20) PRIMARY KEY,
event_ts TIMESTAMP,	
plant VARCHAR(20) NOT NULL,	
line VARCHAR(10) NOT NULL,
shift VARCHAR(10) NOT NULL,
machine_id VARCHAR(20) NOT NULL,
operator_id	VARCHAR(20) NOT NULL,
machine_age_yrs	DECIMAL(4,2),
material_grade VARCHAR(20),	
temp_c DECIMAL(4,1),
humidity_pct DECIMAL(4,1),	
process_speed_units_hr DECIMAL(4,1),
inspection_method VARCHAR(30),	
defect_type	VARCHAR(30),
defect_severity_0to3 INT,	
decision_rework	BOOLEAN,
rework_time_min	DECIMAL(4,1),
final_pass BOOLEAN NOT NULL,
scrap BOOLEAN NOT NULL,
total_cycle_time_min DECIMAL(4,1),
energy_kwh  DECIMAL(6,1),
cost_usd DECIMAL(10,2),
warranty_claim_90d BOOLEAN); 
 
-- TOTAL PRODUCTION -- 
SELECT * FROM manufacturing_data limit 5;  

-- DESCRIBES THE DATA-- 
DESCRIBE manufacturing_data; 

 -- **PRODUCTS THAT PASSED FINAL INSPECTION -- 
SELECT COUNT(*) FROM manufacturing_data WHERE final_pass=1; 

-- PRODUCTS WHICH FAILED FINAL PASS -- 
SELECT COUNT(*) FROM manufacturing_data WHERE final_pass=0; 

 -- PASS_RATE -- 
SELECT SUM(final_pass)*(100)/COUNT(*) AS pass_rate from manufacturing_data ;  

-- TOTAL PRODUCTION, PASS COUNT, FAIL COUNT, PASS RARE, DEFECT RATE, -- 
SELECT COUNT(*) AS total_products, 
SUM(final_pass) AS pass_count, 
COUNT(*)-SUM(final_pass) AS failed_count, 
SUM(final_pass)*(100)/COUNT(*) AS  pass_rate, 
((COUNT(*)-SUM(final_pass))*(100))/COUNT(*) AS defect_rate 	
FROM manufacturing_data;										

-- HIGHEST_PRODUCING_PLANT -- 
SELECT plant,COUNT(event_id) AS highest_producing_plant FROM manufacturing_data 	
GROUP BY plant ORDER BY highest_producing_plant desc limit 1;
 
 -- PERFORMANCE OF PLANTS ACROSS SHIFTS -- 
 SELECT plant,shift,COUNT(*) AS production_count, SUM(final_pass) AS pass_count, 		 
 COUNT(*)-SUM(final_pass) AS failed_count, 
 ROUND(SUM(final_pass)*(100)/COUNT(*),2) AS  pass_rate, 
round(((COUNT(*)-SUM(final_pass))*(100))/COUNT(*),2) AS defect_rate FROM manufacturing_data
GROUP BY plant,shift ORDER BY pass_rate DESC;

-- PLANT_3 FAILED COUNT-- 
SELECT COUNT(*)-SUM(final_pass) AS fail_count FROM manufacturing_data WHERE plant= 'plant_3';  

-- MACHINES HAVING MORE THAN 15%DEFECT RATE -- 
SELECT machine_id,ROUND(((COUNT(*)-SUM(final_pass))*100)/COUNT(*),2) AS defect_rate  
FROM manufacturing_data 
GROUP BY machine_id HAVING defect_rate>15 ORDER BY defect_rate DESC;

-- DEFECT TYPE COUNTS --  
USE manufacturing_project;
SELECT defect_type,COUNT(*) AS individual_defect_type_count FROM manufacturing_data 
WHERE defect_type<> 'none' GROUP BY defect_type ORDER BY individual_defect_type_count DESC; 

-- AVG MANUFACTURING COST BY PLANT-- 
SELECT plant, ROUND(AVG(cost_usd),2) AS manufacturing_cost FROM manufacturing_data GROUP BY plant 
ORDER BY manufacturing_cost DESC;  -- AVG MANUFACTURING COST BY PLANT

-- HIGHEST AND LOWEST MANUFACTURING COST --  
SELECT MAX(cost_usd) AS maximum_cost FROM manufacturing_data;   
SELECT MIN(cost_usd) AS minimum_cost FROM manufacturing_data;

-- DEFECT SEVERITY CATEGORY -- 
SELECT defect_severity_0to3,COUNT(*),
CASE 
	WHEN defect_severity_0to3 = 3 THEN 'critical'
    WHEN defect_severity_0to3 =2 THEN 'moderate'
    WHEN defect_severity_0to3 = 1 THEN 'minor'
    ELSE 'no defect'
END AS defect_severity FROM manufacturing_data 			
GROUP BY defect_severity_0to3 ;

-- DISTINCT MACHINES -- 
SELECT machine_id,COUNT(DISTINCT machine_id) FROM manufacturing_data GROUP BY machine_id;


-- -- MACHINE AGE CATEGORY COUNTS --   
SELECT
    machine_category,
    COUNT(*) AS total_machines
FROM
(
    SELECT DISTINCT
        machine_id,
        CASE
            WHEN machine_age_yrs >= 5 THEN 'Old Machine' 
            ELSE 'New Machine'
        END AS machine_category
    FROM manufacturing_data
) AS machine_list
GROUP BY machine_category;       

 -- MATETIAL GRADE EFFECTING THE DEFECT RATE-- 
SELECT material_grade, COUNT(*)-SUM(final_pass) AS material_defect_count,
ROUND((COUNT(*)-SUM(final_pass))*(100)/COUNT(*),2) AS material_grade_defectrate FROM manufacturing_data 
GROUP BY material_grade;

-- DOES DEFECT_SEVERITY INCEREASES WARRANTY CLAIMS -- 
SELECT defect_severity_0to3,(SUM(warranty_claim_90d)*(100))/COUNT(*) AS warranty_claim_rate 
FROM  manufacturing_data GROUP BY defect_severity_0to3 ORDER BY warranty_claim_rate DESC;   

-- DEOS REWORK PRODUCT HAD HIGH WARRANTY CLAIMS -- 
SELECT decision_rework,COUNT(*) AS rework_count_perc,   
ROUND((SUM(warranty_claim_90d)*(100))/COUNT(*),2) AS warranty_claim_perc FROM manufacturing_data GROUP BY decision_rework;

-- AVERAGE MANUFACTURING COST AMONG PLANTS --  
SELECT plant, ROUND(AVG(cost_usd),2) AS avg_manufacturing_cost, ROUND(((COUNT(*)-SUM(final_pass))*100)/COUNT(*),2) AS defect_rate 
FROM manufacturing_data GROUP BY plant ORDER BY avg_manufacturing_cost DESC;

-- AVERAGE MANUFACTURING COST CONTRIBUTING FOR PASS VS DEFECT PRODUCTS -- 
SELECT final_pass,COUNT(*) AS pass_count ,ROUND(AVG(cost_usd),2)AS manufacturing_cost
FROM manufacturing_data GROUP BY final_pass ;

-- DOES TEMERATURE CHANGES CONTRIBUTE TO DEFECT RATE AND QUALITY -- 
SELECT  
CASE 
WHEN temp_c< 12 THEN 'low temperature'
WHEN temp_c BETWEEN 12 AND 18 THEN 'normal temperature'
 ELSE 'high temperature'
END AS temp_category,COUNT(*) AS total_products, SUM(final_pass) AS pass_count,COUNT(*)-SUM(final_pass) AS failed_products, 
ROUND(((COUNT(*)-SUM(final_pass))*100)/COUNT(*),2) AS defect_rate
 FROM manufacturing_data GROUP BY temp_category;
 
-- DOES HUMIDITY CHANGES CONTRIBUTE TO DEFECT RATE AND CREATING HUMID CATEGORY -- 
SELECT  
CASE 
WHEN humidity_pct< 40 THEN 'low humidity'
WHEN humidity_pct BETWEEN 40 AND 65 THEN 'normal humidity'   
 ELSE 'high humidity'
END AS humidity_category,COUNT(*) AS total_products, SUM(final_pass) AS pass_count,COUNT(*)-SUM(final_pass) AS failed_products, 
ROUND(((COUNT(*)-SUM(final_pass))*100)/COUNT(*),2) AS defect_rate
 FROM manufacturing_data GROUP BY humidity_category ;
 
-- DOES MACHINE AGE EFFECT QUALITY -- 
SELECT  
CASE 
WHEN machine_age_yrs< 9 THEN 'new machine'
 ELSE 'old machine'    				 
END AS age_category,COUNT(*) AS total_products, SUM(final_pass) AS pass_count,COUNT(*)-SUM(final_pass) AS failed_products, 
ROUND(((COUNT(*)-SUM(final_pass))*100)/COUNT(*),2) AS defect_rate
 FROM manufacturing_data GROUP BY age_category;
 

 -- WHICH INSPECTION METHOD IS DETECTING MORE DEFECTS -- 
 SELECT inspection_method, COUNT(*) AS total_products, SUM(final_pass) AS pass_count, 		
COUNT(*)-SUM(final_pass) AS failed_products, ROUND(((COUNT(*)-SUM(final_pass))*100)/COUNT(*),2) AS defect_rate
FROM manufacturing_data GROUP BY inspection_method;
 
 -- WHICH LINE PRODUCES MORE DEFECTS --  
SELECT line, COUNT(*) AS total_products, SUM(final_pass) AS pass_count,
 COUNT(*)-SUM(final_pass) AS failed_products, ROUND(((COUNT(*)-SUM(final_pass))*100)/COUNT(*),2) AS defect_rate
  FROM manufacturing_data GROUP BY line ORDER BY defect_rate DESC;  
  
-- -- WHICH MATERIAL GRADE HAS HIGH DEFECT  -- 
SELECT material_grade, COUNT(*) AS total_products, COUNT(*)-SUM(final_pass) AS failed_counts, 
ROUND(((COUNT(*)-SUM(final_pass))*100)/COUNT(*),2) AS defect_rate
FROM manufacturing_data GROUP BY material_grade ORDER BY defect_rate DESC;

-- DEFECT TYPE CONTRIBUTION TO DEFECT RATE -- 
SELECT defect_type,COUNT(*) AS total_count,ROUND(COUNT(*)*(100)/
(SELECT COUNT(*) FROM manufacturing_data WHERE final_pass=0),2)   		
  AS defect_contribution_rate
FROM manufacturing_data WHERE final_pass=0 AND  defect_type<>'none' GROUP BY defect_type 
ORDER BY defect_contribution_rate DESC  ;


-- DOES REWORKED PRODUCTS HAVE LOW PASS RATE? -- 
SELECT 
CASE
WHEN rework_time_min< 20 THEN 'Low Rework_Time'
WHEN rework_time_min BETWEEN 20 AND 40 THEN 'Medium Rework Time'
ELSE 'High Rework Time'
END AS time_taken_category, COUNT(*) AS total_products, SUM(final_pass) AS pass_count,
COUNT(*)-SUM(final_pass) AS fail_count, ROUND((SUM(final_pass)*100)/COUNT(*),2) AS pass_rate,  
ROUND((((COUNT(*)-SUM(final_pass))*100)/COUNT(*)),2) AS defect_rate FROM manufacturing_data 
GROUP BY time_taken_category 
ORDER BY defect_rate DESC; 
 
-- AVG ENERGY CONSUMED AND AVG MANUFACTURING COST AMONG PLANTS -- 
SELECT plant,COUNT(*) AS total_production, AVG(energy_kwh) AS average_energy_consumed,AVG(cost_usd) AS avg_manufacturing_cost
FROM manufacturing_data GROUP BY plant ORDER BY AVG(energy_kwh) DESC; 		

-- WHICH OPERATOR HAS HIGH DEFECT RATE -- 
SELECT operator_id, COUNT(*) AS total_production, SUM(final_pass) AS pass_count,
COUNT(*)-SUM(final_pass) AS fail_count, ROUND(((COUNT(*)-SUM(final_pass))*100)/COUNT(*),2) AS defect_rate
FROM manufacturing_data GROUP BY operator_id ORDER BY defect_rate DESC;