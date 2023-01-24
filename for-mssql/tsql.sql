-------------------------------------------------PROCEDURA 1-------------------------------------------------

-- Wstawia opłaty do tabeli PAYMENT
-- Pobiera jako parametr: ID_RESERVATION i AMOUNT
-- Sprawdza, czy ID_RESERVATION już istnieje
-- Jeżeli nie istnieje, to nie wstawiamy nowego rekordu

ALTER PROCEDURE project_p1
@id INT,
@amount INT
AS BEGIN
	IF EXISTS (SELECT ID_RESERVATION FROM RESERVATION WHERE ID_RESERVATION = @id)
		INSERT INTO PAYMENT VALUES((SELECT MAX(ID_PAYMENT)+1 FROM PAYMENT), @id, @amount)
    ELSE
        PRINT 'Rezerwacji o numerze ' + CONVERT(VARCHAR, @id)  + ' nie istnieje'
END
GO

SELECT *
FROM PAYMENT

EXECUTE project_p1 99, 1300


-------------------------------------------------PROCEDURA 2-------------------------------------------------

-- nie dodaje pokój, jeśli już istnieje
ALTER PROCEDURE project_p2
@room_n INT,
@floor_n INT,
@info VARCHAR(100)
AS BEGIN
	IF EXISTS (SELECT ROOM_NUMBER FROM ROOM WHERE ROOM_NUMBER <= @room_n)
		PRINT N'Taki pokój już istnieje'
	ELSE
		INSERT INTO ROOM VALUES (@room_n, @floor_n, @info);
END
GO

SELECT *
FROM ROOM

EXECUTE project_p2 29,4, 'Two rooms, four small beds, sea view'

-------------------------------------------------PROCEDURA 3-------------------------------------------------

-- pomaga uzyskać całą inforamcję o pokoju podanej rezerwacji

ALTER PROCEDURE project_p3
@id_res INT
AS BEGIN
	SELECT res.ID_RESERVATION, roo.ROOM_NUMBER, roo.FLOOR, roo.INFO
    FROM RESERVATION res
    INNER JOIN ROOM roo ON res.ROOM_NUMBER = roo.ROOM_NUMBER
    WHERE res.ID_RESERVATION = @id_res;
END
GO

SELECT *
FROM RESERVATION

EXECUTE project_p3  101


-------------------------------------------------WYZWALACZ 1-------------------------------------------------

-- Nie pozwoli na wpisanie gości o imieniach i nazwiskach już istniejących
-- Powinien zablokować jedynie niepoprawnie wpisywanych gości

CREATE TRIGGER project_t1
ON GUEST
FOR INSERT
AS BEGIN
	DELETE FROM GUEST
	WHERE ID_GUEST IN (SELECT i.ID_GUEST FROM inserted i INNER JOIN GUEST g ON i.NAME = g.NAME OR i.LASTNAME = g.LASTNAME WHERE i.ID_GUEST != g.ID_GUEST)
END
GO

SELECT *
FROM GUEST

INSERT INTO GUEST VALUES (1121, 'SANDIE', 'BARR')


-------------------------------------------------WYZWALACZ 2-------------------------------------------------

--   Nie pozwoli usunąć rezerwację, jeśli płatność została dokonana
--   Nie pozwoli zmienić gościa
--   Nie pozwoli wstawić rezerwację, jeśli taka już istniała wcześniej

CREATE TRIGGER project_t2
ON RESERVATION
FOR INSERT, UPDATE, DELETE
AS BEGIN
	IF (SELECT COUNT(*) FROM deleted) = 0
	BEGIN
	    IF EXISTS (SELECT i.ID_RESERVATION FROM inserted i INNER JOIN RESERVATION r ON i.ID_RESERVATION = r.ID_RESERVATION WHERE i.ID_RESERVATION <= r.ID_RESERVATION)
			ROLLBACK
	END
	ELSE IF (SELECT COUNT(*) FROM inserted) = 0
	BEGIN
	    IF EXISTS (SELECT ID_RESERVATION FROM deleted WHERE ID_PAYMENT IS NOT NULL)
			ROLLBACK
	END
	ELSE
	BEGIN
	    IF EXISTS (SELECT d.ID_RESERVATION FROM deleted d INNER JOIN inserted i ON d.ID_RESERVATION = i.ID_RESERVATION WHERE d.ID_GUEST != i.ID_GUEST)
			ROLLBACK
	END
END
GO

SELECT *
FROM ROOM

SELECT *
FROM RESERVATION

-- DELETE
DELETE FROM RESERVATION WHERE ID_RESERVATION = 101
-- INSERT
INSERT INTO RESERVATION VALUES (104, 1, 1119, 3, CONVERT(DATETIME,'1-DEC-2022'), CONVERT(DATETIME,'10-DEC-2023'))
-- UPDATE
UPDATE RESERVATION SET ID_GUEST = 1125 WHERE ID_RESERVATION = 101


-------------------------------------------------WYZWALACZ 3-------------------------------------------------

-- nie pozwoli wstawić lub zmienić AMOUNT dla PAYMENT, jesli będzie <= 100

CREATE TRIGGER project_t3
ON PAYMENT
FOR INSERT, UPDATE
AS BEGIN
	IF EXISTS (SELECT ID_PAYMENT FROM PAYMENT WHERE AMOUNT <= 100)
		ROLLBACK
END
GO

SELECT *
FROM PAYMENT

INSERT INTO PAYMENT VALUES (6, 105, 50)
