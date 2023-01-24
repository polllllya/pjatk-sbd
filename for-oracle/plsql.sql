SET SERVEROUTPUT ON;


-------------------------------------------------PROCEDURA 1----------------------------------------------------

-- Przymuje informację ile piętrz zostałe posprzątane
-- Zwraca informację, jaki pokój został posprzętany lub nie

CREATE OR REPLACE PROCEDURE project_p1(floor_n INT)
AS
    CURSOR kursor IS SELECT ROOM_NUMBER, FLOOR_NUMBER FROM HOTEL_ROOM;
    wiersz kursor%ROWTYPE;
BEGIN
    OPEN kursor;
    LOOP
        FETCH kursor INTO wiersz;
        EXIT WHEN kursor%NOTFOUND;
        
        IF wiersz.FLOOR_NUMBER <= floor_n THEN
            dbms_output.put_line('Pokój ' || wiersz.ROOM_NUMBER || ' został posprzętany');
        ELSE
            dbms_output.put_line('Pokój ' || wiersz.ROOM_NUMBER || ' nie został jeszce posprzętany');
        END IF;
    END LOOP;    
    CLOSE kursor;
END;

SELECT *
FROM HOTEL_ROOM;

EXECUTE project_p1(3);


-------------------------------------------------PROCEDURA 2----------------------------------------------------

-- Liczę zniżkę na podróż dla każdej rezerwacji
-- Jeśli płatność za rezerwację > am1 - zniżka 10%
-- Jeśli płatność za rezerwację > am2 - zniżka 5%

CREATE OR REPLACE PROCEDURE project_p2(trip_cost INT, am1 INT, am2 INT)
AS
    CURSOR kursor IS SELECT ID_RESERVATION, AMOUNT FROM PAYMENT;
    wiersz kursor%ROWTYPE;
BEGIN    
    OPEN kursor;
    LOOP
        FETCH kursor INTO wiersz;
        EXIT WHEN kursor%NOTFOUND;
        
        IF wiersz.AMOUNT > am1 THEN
            dbms_output.put_line('Dla rezerwacji ' || wiersz.ID_RESERVATION || ' opłata za podróż wynosi: ' || (trip_cost - (trip_cost * 10 /100)));
        ELSIF wiersz.AMOUNT > am2 THEN
            dbms_output.put_line('Dla rezerwacji ' || wiersz.ID_RESERVATION || ' opłata za podróż wynosi: ' || (trip_cost - (trip_cost * 5 /100)));
        ELSE
            dbms_output.put_line('Dla rezerwacji ' || wiersz.ID_RESERVATION || ' opłata za podróż wynosi: ' || trip_cost);
        END IF;
    END LOOP;    
    CLOSE kursor;
END;

SELECT *
FROM PAYMENT;

EXECUTE project_p2 (300, 2500, 1000);

-------------------------------------------------PROCEDURA 3----------------------------------------------------

-- Dodaje (po remońcie) nowy pokój
-- Ale najpierw sprawdza, czy podany pokój przpadkiem nie był wcześniej dodany

CREATE OR REPLACE PROCEDURE project_p3(room_n INT, floor_n INT, inf VARCHAR)
AS
    ile INT;
BEGIN
    SELECT COUNT(*) INTO ile
    FROM ROOM
    WHERE ROOM_NUMBER = room_n;
    IF ile = 0 THEN
        INSERT INTO HOTEL_ROOM VALUES(room_n, floor_n, inf);
    ELSE
        dbms_output.put_line('Taki pokój już istnieje');
    END IF;
END;

SELECT *
FROM HOTEL_ROOM;

EXECUTE project_p3 (25,2,'One room, one large bed, mountain view');



-------------------------------------------------WYZWALACZ 1----------------------------------------------------

-- Nie pozwoli na zmianę płatności w mniejszą stronę
-- I usuwanie jakiejkolwiek płatności
 
CREATE OR REPLACE TRIGGER project_t1
BEFORE UPDATE OR DELETE
ON PAYMENT
FOR EACH ROW
BEGIN
	IF UPDATING THEN
		IF :NEW.AMOUNT < :OLD.AMOUNT THEN
			:NEW.AMOUNT := :OLD.AMOUNT;
            dbms_output.put_line('Dla rezerwacji ' || :OLD.ID_RESERVATION ||' nie mozna zmienic płatność na mniejszą');
		END IF;
	ELSE
		raise_application_error(-20500, 'Nie mozna usuwać');
	END IF;
END;

SELECT *
FROM PAYMENT;

UPDATE PAYMENT SET AMOUNT = 2000 WHERE ID_RESERVATION = 102;
DELETE PAYMENT WHERE ID_RESERVATION = 100;


-------------------------------------------------WYZWALACZ 2----------------------------------------------------

-- Nie pozwoli:
-- przy wstawianiu wpisać datę wyjazdu mniej niż datę przyjazdu
-- zmienić gościa dla jakiejkolwiek rezerwacji
-- usunąć reserwację, jeśli ona została opłacona

CREATE OR REPLACE TRIGGER project_t2
BEFORE INSERT OR UPDATE OR DELETE
ON RESERVATION
FOR EACH ROW
DECLARE 
    ile INT;
BEGIN
	IF INSERTING THEN
		SELECT COUNT(*) INTO ile
		FROM RESERVATION
		WHERE :NEW.START_DATE >= :NEW.END_DATE;
		IF ile > 0 THEN
			raise_application_error(-20500, 'Data wyjazdu nie może być wcześniej niż data przyjazdu');
		END IF;
	ELSIF UPDATING THEN
		IF :OLD.ID_GUEST != :NEW.ID_GUEST THEN
			:NEW.ID_GUEST := :OLD.ID_GUEST;
		END IF;
	ELSE
		IF :OLD.ID_PAYMENT IS NOT NULL THEN
			raise_application_error(-20500, 'Nie mozna usuwac');
		END IF;
	END IF;
END;

SELECT *
FROM RESERVATION;

-- INSERT
INSERT INTO RESERVATION VALUES
        (109, 25, 1115, 5, TO_DATE('2022-06-07','YYYY-MM-DD'), TO_DATE('2022-06-01','YYYY-MM-DD'));
        
-- UPDATE
UPDATE RESERVATION SET ID_GUEST = 1111 WHERE ID_RESERVATION = 100;

-- DELETE
DELETE RESERVATION WHERE ID_RESERVATION = 100;

-------------------------------------------------WYZWALACZ 3----------------------------------------------------

-- Nie powzwoli wstawić nowy pokój, jeśli przy wstawianiu pokój już isniał

CREATE OR REPLACE TRIGGER proejct_t3
BEFORE INSERT
ON HOTEL_ROOM
FOR EACH ROW
BEGIN
	IF :NEW.ROOM_NUMBER <= 29 THEN
		raise_application_error(-20500, 'Taki pokój już istnieje');
	END IF;
END;

SELECT *
FROM HOTEL_ROOM;

INSERT INTO HOTEL_ROOM VALUES
        (30, 4, 'One room, one large bed, mountain view');
