--database Postgres

--Create Tables--
--This portion is to create detailed table--

Drop Table if exists detailed;

CREATE Table detailed (
    inventory_id int,
    film_id int,
    last_update timestamp,
    rental_id int,
    rental_date timestamp,
    release_year int,
    title varchar(255),
)

SELECT * FROM detailed; -- shows empty table

--This portion is to create summary table--

Drop Table if exists summary;

CREATE Table summary (
    times_rented int,
    title varchar(255),
    release_year char(4),
)

SELECT * FROM summary; -- shows empty table


-- insert data into the detailed table--
INSERT INTO detailed (inventory_id, film_id, last_update, rental_id, rental_date, release_year, title)
SELECT inventory.inventory_id, film.film_id, inventory.last_update, rental.rental_id, rental.rental_date, film.release_year, film.title
FROM inventory
INNER JOIN film ON inventory.film_id = film.film_id
INNER JOIN rental ON inventory.inventory_id = rental.inventory_id;

SELECT * FROM detailed;





SELECT * FROM detailed; -- shows data in the detailed table

-- create function that counts how many times a film has been rented--
CREATE OR REPLACE FUNCTION times_rented(title varchar(255))
RETURNS int AS $$
DECLARE
    times_rented int;
BEGIN
    SELECT COUNT(*) INTO times_rented FROM detailed WHERE title = $1;
    RETURN times_rented;
END;







-- create a trigger that refreshes data into the summary table when a new film is rented--
CREATE OR REPLACE FUNCTION update_summary()
RETURNS trigger AS $$
BEGIN
    IF (NEW.title NOT IN (SELECT title FROM summary)) THEN
        INSERT INTO summary (times_rented, title, release_year)
        VALUES (times_rented(NEW.title), NEW.title, NEW.release_year);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_summary
AFTER INSERT ON detailed
FOR EACH ROW
EXECUTE PROCEDURE update_summary();




-- stored procedure that can be used to refresh the data in both tables.

CREATE OR REPLACE PROCEDURE refresh_data()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE detailed;
    INSERT INTO detailed (inventory_id, film_id, last_update, rental_id, rental_date, release_year, title)
    SELECT inventory.inventory_id, film.film_id, inventory.last_update, rental.rental_id, rental.rental_date, film.release_year, film.title
    FROM inventory
    INNER JOIN film ON inventory.film_id = film.film_id
    INNER JOIN rental ON inventory.inventory_id = rental.inventory_id;
END;
$$;
$$;



CALL refresh_data(); -- calls the procedure refresh_data()

SELECT * FROM detailed; -- shows data in the detailed table

 -- shows data in the summary table ordered by times_rented in descending order
SELECT * FROM summary ORDER BY times_rented DESC;

