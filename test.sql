--This code is ran in PGAdmin which runs the DVD rental postgres Database. Code was written in VS Code with testing done in PGAdmin.


-- This section creates the tables Detailed and Summary

DROP TABLE IF EXISTS detailed;

CREATE TABLE detailed (
    inventory_id int,
    film_id int,
    last_update timestamp,
    rental_id int,
    rental_date timestamp,
    release_year int,
    title varchar(255),
);

SELECT * FROM detailed;

DROP TABLE IF EXISTS summary;

CREATE TABLE summary (
    times_rented int,
    title varchar(255),
    release_year char(4),
);

SELECT * FROM summary;


--This Section adds data to the Detailed table.

INSERT INTO detailed (inventory_id, film_id, last_update, rental_id, rental_date, release_year, title)
SELECT inventory.inventory_id, film.film_id, inventory.last_update, rental.rental_id, rental.rental_date, film.release_year, film.title
FROM inventory
INNER JOIN film ON inventory.film_id = film.film_id
INNER JOIN rental ON inventory.inventory_id = rental.inventory_id;

SELECT * FROM detailed;


--This creates the Transform function


CREATE OR REPLACE FUNCTION times_rented(title varchar(255))
RETURNS int AS $$
DECLARE
    times_rented int;
BEGIN
    SELECT COUNT(*) INTO times_rented FROM detailed WHERE detailed.title = $1;
    RETURN times_rented;
END;
$$ LANGUAGE plpgsql;

ALTER TABLE detailed ADD COLUMN times_rented int;

UPDATE detailed SET times_rented = times_rented(title);

--This is the trigger function used to update the summary section.

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


--This is the stored procedure used.
--Procedure should be ran every 2-3 months. this can be automated with a task scheduler like pgAgent

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

    UPDATE detailed SET times_rented = times_rented(title);

END;
$$;

CALL refresh_data(); 

SELECT * FROM detailed;
SELECT * FROM summary;

