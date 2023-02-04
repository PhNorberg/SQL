/*
Lab 2 report Jacob Ringfjord jacri901 and Philip Norberg piho637
*/

/*
Drop all user created tables that have been created when solving the lab
*/

DROP TABLE IF EXISTS myTable CASCADE;
DROP VIEW IF EXISTS price_view CASCADE;
DROP VIEW IF EXISTS debitandtotal CASCADE;
DROP VIEW IF EXISTS jbsale_supply CASCADE;

/* 
1. List all employees, i.e., all tuples in the jbemployee relation. 
*/

SELECT * FROM jbemployee;

/* 
2. List the name of all departments in alphabetical order. Note: by “name”
we mean the name attribute in the jbdept relation. 
*/

SELECT NAME FROM jbdept ORDER BY name;

/* 
3. What parts are not in store? Note that such parts have the value 0 (zero)
for the qoh attribute (qoh = quantity on hand) 
*/

SELECT NAME FROM jbparts WHERE qoh = 0;

/* 
4. List all employees who have a salary between 9000 (included) and
10000 (included)? 
*/

SELECT NAME FROM jbemployee WHERE Salary >= 9000 AND Salary <= 10000;

/* 
5. List all employees together with the age they had when they started
working? Hint: use the startyear attribute and calculate the age in the
SELECT clause 
*/

SELECT NAME, STARTYEAR - BIRTHYEAR AS "AGE" FROM jbemployee;

/* 
6. List all employees who have a last name ending with “son” 
*/

SELECT NAME FROM jbemployee WHERE NAME LIKE '%son,%';

/* 
7. Which items (note items, not parts) have been delivered by a supplier
called Fisher-Price? Formulate this query by using a subquery in the
WHERE clause
*/

SELECT NAME FROM jbitem WHERE SUPPLIER = (SELECT ID FROM jbsupplier WHERE NAME = 'FISHER-PRICE');

/* 
8. Formulate the same query as above, but without a subquery 
*/

SELECT jbitem.NAME FROM jbsupplier, jbitem WHERE jbsupplier.NAME = 'FISHER-PRICE' AND jbsupplier.ID = jbitem.SUPPLIER;

/* 
9. List all cities that have suppliers located in them. Formulate this query
using a subquery in the WHERE clause.
*/

SELECT NAME FROM jbcity WHERE ID IN (SELECT CITY FROM jbsupplier);

/* 
10. What is the name and the color of the parts that are heavier than a card
reader? Formulate this query using a subquery in the WHERE clause.
(The query must not contain the weight of the card reader as a constant;
instead, the weight has to be retrieved within the query.) 
*/

SELECT NAME, COLOR FROM jbparts WHERE Weight > (SELECT weight FROM jbparts WHERE name like 'card reader');

/* 
11. Formulate the same query as above, but without a subquery. Again, the
query must not contain the weight of the card reader as a constant. 
*/

SELECT parts1.NAME, parts1.COLOR FROM jbparts parts1, jbparts parts2 WHERE parts1.WEIGHT > parts2.WEIGHT AND parts2.NAME = 'card reader';

/* 
12. What is the average weight of all black parts?
*/

SELECT AVG(WEIGHT) FROM jbparts WHERE COLOR = 'BLACK';

/* 
13. For every supplier in Massachusetts (“Mass”), retrieve the name and the
total weight of all parts that the supplier has delivered? Do not forget to
take the quantity of delivered parts into account. Note that one row
should be returned for each supplier. 
*/

SELECT x.name, y.total_weight FROM (SELECT id, name FROM jbsupplier WHERE city IN (SELECT id FROM jbcity WHERE state='Mass')) x INNER JOIN (SELECT supply.supplier, SUM(parts.weight*supply.quan) AS "total_weight" FROM jbparts parts, jbsupply supply WHERE parts.id=supply.part GROUP BY supply.supplier) y ON x.id = y.supplier;

/* 
14. Create a new relation with the same attributes as the jbitems relation by
using the CREATE TABLE command where you define every attribute
explicitly (i.e., not as a copy of another table). Then, populate this new
relation with all items that cost less than the average price for all items.
Remember to define the primary key and foreign keys in your table!
*/

CREATE TABLE myTable (
ID integer,
NAME varchar(25),
DEPT integer not null,
PRICE  integer,
QOH integer,
SUPPLIER integer not null,
CONSTRAINT pk_item PRIMARY KEY(id),
CONSTRAINT fk_item FOREIGN KEY(SUPPLIER) references jbsupplier(ID));

INSERT INTO myTable (ID, NAME, DEPT, PRICE, QOH, SUPPLIER) SELECT ID, NAME, DEPT, PRICE, QOH, SUPPLIER FROM jbitem WHERE PRICE > (SELECT AVG(PRICE) FROM jbitem);
SELECT * FROM myTable;

/* 
15. Create a view that contains the items that cost less than the average
price for items. 
*/

CREATE VIEW price_view AS SELECT * FROM jbitem WHERE jbitem.price < (SELECT AVG(sub.price) FROM jbitem as sub);
SELECT * FROM price_view;

DROP TABLE myTable;
DROP VIEW price_view;

/* 
16. What is the difference between a table and a view? One is static and the
other is dynamic. Which is which and what do we mean by static
respectively dynamic? 
*/

/* A view does not store data, they derive it from a table. 
The table is a database object that actually stores the data. 
Table is static. View is dynamic since it is just a query with a name.

/* 
17. Create a view that calculates the total cost of each debit, by considering
price and quantity of each bought item. (To be used for charging
customer accounts). The view should contain the sale identifier (debit)
and the total cost. In the query that defines the view, capture the join
condition in the WHERE clause (i.e., do not capture the join in the
FROM clause by using keywords inner join, right join or left join). 
*/

CREATE VIEW debitandtotal AS (SELECT jbsale.debit, jbsale.quantity * jbitem.price AS totalcost FROM jbitem, jbsale WHERE jbsale.item = jbitem.id);
SELECT * FROM debitandtotal;

DROP VIEW debitandtotal;

/* 
18. Do the same as in the previous point, but now capture the join conditions
in the FROM clause by using only left, right or inner joins. Hence, the
WHERE clause must not contain any join condition in this case. Motivate
why you use type of join you do (left, right or inner), and why this is the
correct one (in contrast to the other types of joins). 
*/

SELECT jbsale.debit, jbsale.quantity * jbitem.price AS totalcost FROM jbsale JOIN jbitem ON jbsale.item = jbitem.id;

/* LEFT OUTER or INNER JOIN produces the right output. Using RIGHT OUTER gives a bunch of null rows due to the fact
that every tuple in jbitem is included in the result table, which we dont want. We want the jbsale debits to be mapped to the items, hence
LEFT OUTER or INNER. INNER JOIN is generally faster than OUTER JOINs, but since the table is so small it probably doesnt matter in this case. */

/* 
19. Oh no! An earthquake!

a) Remove all suppliers in Los Angeles from the jbsupplier table. This
will not work right away. Instead, you will receive an error with error
code 23000 which you will have to solve by deleting some other related tuples. 
However, do not delete more tuples from other tables
than necessary, and do not change the structure of the tables (i.e.,
do not remove foreign keys). Also, you are only allowed to use “Los
Angeles” as a constant in your queries, not “199” or “900”.
*/

DELETE FROM jbsale WHERE item = (SELECT item FROM jbsale WHERE item in (SELECT id FROM jbitem WHERE supplier = (SELECT id FROM jbsupplier WHERE city = (SELECT id FROM jbcity WHERE name like 'Los Angeles')))); 
DELETE FROM jbitem WHERE id in (SELECT id FROM jbitem WHERE supplier = (SELECT id FROM jbsupplier WHERE city = (SELECT id FROM jbcity WHERE name like 'Los Angeles'))); 
DELETE FROM jbsupplier WHERE id in (SELECT id FROM jbsupplier WHERE city = (SELECT id FROM jbcity WHERE name like 'Los Angeles')); 

/* 
b) Explain what you did and why.
*/

/* we need to remove the child relations from bottom up. First we need to remove the sale which points to the item. 
Then we need to remove the items that points to the supplier.alter When this is done nothing is pointning to the supplier 
and we can delete the supplier. */

/* 
20. An employee has tried to find out which suppliers have delivered items
that have been sold. To this end, the employee has created a view and
a query that lists the number of items sold from a supplier.

Now, the employee also wants to include the suppliers that have
delivered some items, although for whom no items have been sold so
far. In other words, he wants to list all suppliers that have supplied any
item, as well as the number of these items that have been sold. Help
him! Drop and redefine the jbsale_supply view to also consider suppliers
that have delivered items that have never been sold. 
*/

CREATE VIEW jbsale_supply AS 
SELECT jbi.name item, jbsu.name supplier, jbsa.quantity FROM jbitem jbi LEFT JOIN jbsupplier jbsu ON jbi.supplier=jbsu.id LEFT JOIN jbsale jbsa on jbsa.item = jbi.id;

SELECT supplier, sum(quantity) AS sum FROM jbsale_supply GROUP BY supplier;

DROP VIEW jbsale_supply;
