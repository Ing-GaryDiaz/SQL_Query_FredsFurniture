SET
	SEARCH_PATH TO CC_USER;

--Query 1 ---------------------------------------------------
SELECT
	*
FROM
	CC_USER.STORE
LIMIT
	10;

--Query 2 ---------------------------------------------------
-- order_id:
SELECT
	COUNT(DISTINCT (ORDER_ID)) AMOUNT_ORDERS
FROM
	CC_USER.STORE;

--Rta: La cantidad de ordenes del mes es 100 
--customer_id:
SELECT
	COUNT(DISTINCT (CUSTOMER_ID)) AMOUNT_CUSTOMERS
FROM
	CC_USER.STORE;

--Rta: La cantidad de clientes del mes es 80
--Query 3 ---------------------------------------------------
SELECT
	CUSTOMER_ID,
	CUSTOMER_EMAIL,
	CUSTOMER_PHONE
FROM
	CC_USER.STORE
WHERE
	CUSTOMER_ID = 1;

--Rta: 2 registros repetidos Raamiz1@email.com, 555-555-7900, es decir dos pedidos del mismo cliente.
--Con la sgte Query, complemento el conocimiento de cuales clientes hicieron mas de un pedido,
--pero además cuantos pedidos hizo cada uno de ellos
SELECT
	CUSTOMER_ID,
	COUNT(ORDER_ID) AS TOTAL_PEDIDOS
FROM
	CC_USER.STORE
GROUP BY
	CUSTOMER_ID
HAVING
	COUNT(ORDER_ID) > 1;

--Query 4 ---------------------------------------------------
/*Probablemente haya aún más datos repetidos en las columnas relacionadas con los artículos. Escribe una consulta para devolver 
item_1_id, item_1_name y item_1_price, donde item_1_id = 4.
¿Cuántos pedidos incluyen este artículo como item_1?*/
SELECT
	ITEM_1_ID,
	ITEM_1_NAME,
	ITEM_1_PRICE
FROM
	CC_USER.STORE
WHERE
	ITEM_1_ID = 4;

--Rta: Con item_1_id = 4 existen 3 registros
--Query 5 -------INICIAMOS EL PROCESO DE NORMALIZACIÓN : --------------------------
-- Creación de la tabla customers:
CREATE TABLE CUSTOMERS AS
SELECT DISTINCT
	CUSTOMER_ID,
	CUSTOMER_PHONE,
	CUSTOMER_EMAIL
FROM
	CC_USER.STORE;

--Query 6 ---------------------------------------------------
-- Designamos Pk a la tabla customers de manera disociada a la query de creación de la tabla,
-- ya que esta viene de una tabla ya existente:
ALTER TABLE CUSTOMERS
ADD PRIMARY KEY (CUSTOMER_ID);

--Query 7 ---------------------------------------------------
-- Creación de la tabla items, teniendo en cuenta que existen item_x_id distintos:
CREATE TABLE ITEMS AS
SELECT DISTINCT
	ITEM_1_ID AS ITEM_ID,
	ITEM_1_NAME AS ITEM_NAME,
	ITEM_1_PRICE AS ITEM_PRICE
FROM
	CC_USER.STORE
WHERE
	ITEM_1_ID IS NOT NULL
	AND ITEM_1_NAME IS NOT NULL
	AND ITEM_1_PRICE IS NOT NULL
UNION
SELECT DISTINCT
	ITEM_2_ID,
	ITEM_2_NAME,
	ITEM_2_PRICE
FROM
	CC_USER.STORE
WHERE
	ITEM_2_ID IS NOT NULL
	AND ITEM_2_NAME IS NOT NULL
	AND ITEM_2_PRICE IS NOT NULL
UNION
SELECT DISTINCT
	ITEM_3_ID,
	ITEM_3_NAME,
	ITEM_3_PRICE
FROM
	CC_USER.STORE
WHERE
	ITEM_3_ID IS NOT NULL
	AND ITEM_3_NAME IS NOT NULL
	AND ITEM_3_PRICE IS NOT NULL;

--Query 8 ---------------------------------------------------
-- Designamos Pk a la tabla items:
ALTER TABLE ITEMS
ADD PRIMARY KEY (ITEM_ID);

--Query 9 ---------------------------------------------------  
-- Creación de la tabla orders_items, teniendo en cuenta que es
-- tabla intermedia y debe gestionar la relación de la ya creada tabla 'items' 
-- y la proxima a crear 'orders':
CREATE TABLE ORDERS_ITEMS AS
SELECT
	ORDER_ID,
	ITEM_1_ID AS ITEM_ID,
	ITEM_1_NAME AS ITEM_NAME,
	ITEM_1_PRICE AS ITEM_PRICE
FROM
	CC_USER.STORE
WHERE
	ITEM_1_ID IS NOT NULL
UNION ALL
SELECT
	ORDER_ID,
	ITEM_2_ID AS ITEM_ID,
	ITEM_2_NAME AS ITEM_NAME,
	ITEM_2_PRICE AS ITEM_PRICE
FROM
	CC_USER.STORE
WHERE
	ITEM_2_ID IS NOT NULL
UNION ALL
SELECT
	ORDER_ID,
	ITEM_3_ID AS ITEM_ID,
	ITEM_3_NAME AS ITEM_NAME,
	ITEM_3_PRICE AS ITEM_PRICE
FROM
	CC_USER.STORE
WHERE
	ITEM_3_ID IS NOT NULL;

--Query 10 --------------------------------------------------- 
--Creación de la tabla orders, teniendo en cuenta la tabla 'store',
-- trayendo de allí customer_id.
CREATE TABLE ORDERS AS
SELECT DISTINCT
	ORDER_ID,
	CUSTOMER_ID,
	ORDER_DATE
FROM
	CC_USER.STORE
WHERE
	ORDER_ID IS NOT NULL;

--Query 11 ---------------------------------------------------
-- Designamos Pk a la tabla ordes:
ALTER TABLE ORDERS
ADD CONSTRAINT PK_ORDERS PRIMARY KEY (ORDER_ID);

--Query 12 ---------------------------------------------------
--1. Designamos la columna customer_id como Fk referenciada desde la 
-- columna 'customer_id' de la tabla ya creada 'customers'
ALTER TABLE ORDERS
ADD FOREIGN KEY (CUSTOMER_ID) REFERENCES CUSTOMERS (CUSTOMER_ID);

--2. Designamos la columna item_id como Fk
ALTER TABLE ORDERS_ITEMS
ADD FOREIGN KEY (ITEM_ID) REFERENCES ITEMS (ITEM_ID);

--Query 13 ---------------------------------------------------
--Designamos la columna order_id como Fk
ALTER TABLE ORDERS_ITEMS
ADD FOREIGN KEY (ORDER_ID) REFERENCES ORDERS (ORDER_ID);

--Query 14 ---------------------------------------------------
--Consulta desde 'store'(tabla original no normalizada)
SELECT DISTINCT
	CUSTOMER_EMAIL
FROM
	CC_USER.STORE
WHERE
	ORDER_DATE > '2019-07-25';

--Query 15 ---------------------------------------------------
--Consulta desde 'customers' (Tabla producto de la normalización)
SELECT DISTINCT
	CUSTOMER_EMAIL
FROM
	CUSTOMERS
	JOIN ORDERS ON CUSTOMERS.CUSTOMER_ID = ORDERS.CUSTOMER_ID
WHERE
	ORDERS.ORDER_DATE > '2019-07-25';

--Query 16 ---------------------------------------------------
-- Consulta desde la tala original 'store':
WITH
	ITEMS_UNION AS (
		SELECT
			ITEM_1_ID AS ITEM_ID
		FROM
			CC_USER.STORE
		WHERE
			ITEM_1_ID IS NOT NULL
		UNION ALL
		SELECT
			ITEM_2_ID
		FROM
			CC_USER.STORE
		WHERE
			ITEM_2_ID IS NOT NULL
		UNION ALL
		SELECT
			ITEM_3_ID
		FROM
			CC_USER.STORE
		WHERE
			ITEM_3_ID IS NOT NULL
	)
SELECT
	ITEM_ID,
	COUNT(*) AS ORDER_COUNT
FROM
	ITEMS_UNION
GROUP BY
	ITEM_ID
ORDER BY
	ORDER_COUNT DESC;

--Query 17 ---------------------------------------------------
--Consulta desde la nueva tabla orders_items:
SELECT
	ORDERS_ITEMS.ITEM_ID,
	COUNT(DISTINCT ORDERS_ITEMS.ORDER_ID) AS ORDER_COUNT
FROM
	ORDERS_ITEMS
GROUP BY
	ORDERS_ITEMS.ITEM_ID
ORDER BY
	ORDER_COUNT DESC;

--Observamos la simplicidad, brevedad, precisión y claridad en esta consulta, para obtener los datos requeridos.
--Query 18 ---------------------------------------------------
-- No normalizada
SELECT
	CUSTOMER_ID,
	ITEM_1_NAME AS ITEM_NAME,
	ORDER_DATE
FROM
	CC_USER.STORE
WHERE
	ITEM_1_NAME IS NOT NULL
UNION ALL
SELECT
	CUSTOMER_ID,
	ITEM_2_NAME,
	ORDER_DATE
FROM
	CC_USER.STORE
WHERE
	ITEM_2_NAME IS NOT NULL
UNION ALL
SELECT
	CUSTOMER_ID,
	ITEM_3_NAME,
	ORDER_DATE
FROM
	CC_USER.STORE
WHERE
	ITEM_3_NAME IS NOT NULL
ORDER BY
	CUSTOMER_ID;

--Normalizada
SELECT
	CUSTOMERS.CUSTOMER_ID,
	ITEMS.ITEM_NAME,
	ORDERS.ORDER_DATE
FROM
	CUSTOMERS
	JOIN ORDERS ON CUSTOMERS.CUSTOMER_ID = ORDERS.CUSTOMER_ID
	JOIN ORDERS_ITEMS ON ORDERS.ORDER_ID = ORDERS_ITEMS.ORDER_ID
	JOIN ITEMS ON ORDERS_ITEMS.ITEM_ID = ITEMS.ITEM_ID
ORDER BY
	CUSTOMERS.CUSTOMER_ID;

--Query 19 ---------------------------------------------------
WITH
	ITEMS_UNION AS (
		SELECT
			ITEM_1_ID AS ITEM_ID,
			ORDER_ID
		FROM
			CC_USER.STORE
		WHERE
			ITEM_1_ID IS NOT NULL
		UNION ALL
		SELECT
			ITEM_2_ID,
			ORDER_ID
		FROM
			CC_USER.STORE
		WHERE
			ITEM_2_ID IS NOT NULL
		UNION ALL
		SELECT
			ITEM_3_ID,
			ORDER_ID
		FROM
			CC_USER.STORE
		WHERE
			ITEM_3_ID IS NOT NULL
	)
SELECT
	ITEM_ID,
	COUNT(DISTINCT ORDER_ID) AS ORDER_COUNT
FROM
	ITEMS_UNION
GROUP BY
	ITEM_ID
ORDER BY
	ORDER_COUNT DESC;

--NOrmalizada
/*
No necesitamos UNION ALL, porque en orders_items cada ítem ya está estructurado correctamente en una fila con order_id.
Tampoco necesitamos crear estructuras temporales usando WITH.
La información ya está separada en tablas correctas, por lo que la consulta es más limpia y rápida.*/
SELECT
	ORDERS_ITEMS.ITEM_ID,
	COUNT(DISTINCT ORDERS_ITEMS.ORDER_ID) AS ORDER_COUNT
FROM
	ORDERS_ITEMS
GROUP BY
	ORDERS_ITEMS.ITEM_ID
ORDER BY
	ORDER_COUNT DESC;

---------------------------------------------------
---------------------------------------------------
--Other questions you might try to answer: 
SELECT
	CUSTOMERS.CUSTOMER_EMAIL,
	COUNT(ORDERS.ORDER_ID) ORDERS_COUNT
FROM
	CUSTOMERS
	JOIN ORDERS ON CUSTOMERS.CUSTOMER_ID = ORDERS.CUSTOMER_ID
GROUP BY
	CUSTOMERS.CUSTOMER_ID,
	CUSTOMERS.CUSTOMER_EMAIL
HAVING
	COUNT(ORDERS.ORDER_ID) > 1;

--Rta: 20 clientes hicieron mas de un pedido (casualmente, todos esos 20 cliente hicieron 2 pedidos)
------------------------	
SELECT
	COUNT(DISTINCT ORDERS.ORDER_ID) AS LAMP_ORDERS
FROM
	ORDERS
	JOIN ORDERS_ITEMS ON ORDERS.ORDER_ID = ORDERS_ITEMS.ORDER_ID
	JOIN ITEMS ON ORDERS_ITEMS.ITEM_ID = ITEMS.ITEM_ID
WHERE
	ORDERS.ORDER_DATE > '2019-07-15'
	AND ITEMS.ITEM_NAME = 'lamp';

--Rta: 5 ordenes incluían una lampara
-------------------------
SELECT
	COUNT(DISTINCT ORDERS.ORDER_ID) AS CHAIR_ORDERS
FROM
	ORDERS
	JOIN ORDERS_ITEMS ON ORDERS.ORDER_ID = ORDERS_ITEMS.ORDER_ID
	JOIN ITEMS ON ORDERS_ITEMS.ITEM_ID = ITEMS.ITEM_ID
WHERE
	ITEMS.ITEM_NAME = 'chair';

--Rta: 3 ordenes incluían una silla
