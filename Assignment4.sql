DROP TABLE IF EXISTS Payment CASCADE;
DROP TABLE IF EXISTS hasPassengerReservation CASCADE;
DROP TABLE IF EXISTS Reservation CASCADE;
DROP TABLE IF EXISTS Passenger CASCADE;
DROP TABLE IF EXISTS Flight CASCADE;
DROP TABLE IF EXISTS weeklySchedule CASCADE;
DROP TABLE IF EXISTS Route CASCADE;
DROP TABLE IF EXISTS Airport CASCADE;
DROP TABLE IF EXISTS yearlyProfitFactor CASCADE;
DROP TABLE IF EXISTS weeklyProfitFactor CASCADE;

DROP VIEW IF EXISTS allFlights CASCADE;

DROP PROCEDURE IF EXISTS addYear;
DROP PROCEDURE IF EXISTS addDay;
DROP PROCEDURE IF EXISTS addDestination;
DROP PROCEDURE IF EXISTS addRoute;
DROP PROCEDURE IF EXISTS addFlight;
DROP PROCEDURE IF EXISTS addReservation;
DROP PROCEDURE IF EXISTS addPassenger;
DROP PROCEDURE IF EXISTS addContact;
DROP PROCEDURE IF EXISTS addPayment;

DROP FUNCTION IF EXISTS calculateFreeSeats;
DROP FUNCTION IF EXISTS calculatePrice;
DROP FUNCTION IF EXISTS uniqueRandomNumber;

DROP TRIGGER IF EXISTS generateTicketNumber;

CREATE TABLE Airport (
Airport_code VARCHAR(3) NOT NULL,
Airport_name VARCHAR(30) NOT NULL,
Country VARCHAR(30) NOT NULL,
CONSTRAINT PRIMARY KEY(Airport_code)
);

CREATE TABLE Route (
Route_id INTEGER NOT NULL AUTO_INCREMENT,
Route_price DOUBLE NOT NULL,
Departure_airport_code VARCHAR(3) NOT NULL,
Arrival_airport_code VARCHAR(3) NOT NULL,
Year INTEGER NOT NULL,
CONSTRAINT PRIMARY KEY(Route_id, Year, Departure_airport_code, Arrival_airport_code),
CONSTRAINT FOREIGN KEY(Departure_airport_code) references Airport(Airport_code) on delete cascade,
CONSTRAINT FOREIGN KEY(Arrival_airport_code) references Airport(Airport_code) on delete cascade
);

CREATE TABLE weeklySchedule (
ID INTEGER NOT NULL AUTO_INCREMENT,
Day VARCHAR(10) NOT NULL,
Year INTEGER NOT NULL,
Departure_time TIME NOT NULL,
Route_id INTEGER NOT NULL,
CONSTRAINT PRIMARY KEY(ID),
CONSTRAINT FOREIGN KEY(Route_id) references Route(Route_id) on delete cascade
);

CREATE TABLE Flight (
Flightnumber INTEGER NOT NULL AUTO_INCREMENT,
Year INTEGER NOT NULL,
Week INTEGER NOT NULL,
Weekly_schedule_id INTEGER NOT NULL,
CONSTRAINT PRIMARY KEY(Flightnumber),
CONSTRAINT FOREIGN KEY(Weekly_schedule_id) references weeklySchedule(ID) on delete cascade
);

CREATE TABLE Passenger (
Passport_number INTEGER NOT NULL,
Name VARCHAR(30) NOT NULL,
CONSTRAINT PRIMARY KEY(Passport_number)
);

CREATE TABLE Reservation (
Reservation_number INTEGER NOT NULL,
Email VARCHAR(30),
Phone_number BIGINT,
Number_of_passengers INTEGER NOT NULL,
Flightnumber INTEGER NOT NULL,
Passport_number INTEGER,
CONSTRAINT PRIMARY KEY(Reservation_number),
CONSTRAINT FOREIGN KEY(Flightnumber) references Flight(Flightnumber) on delete cascade,
CONSTRAINT FOREIGN KEY(Passport_number) references Passenger(Passport_number) on delete cascade
);

CREATE TABLE Payment (
Payment_id INTEGER NOT NULL AUTO_INCREMENT,
Creditcard_number BIGINT NOT NULL,
Creditcard_holder VARCHAR(30) NOT NULL,
Reservation_number INTEGER NOT NULL,
Total_price DOUBLE NOT NULL,
CONSTRAINT PRIMARY KEY(Payment_id),
CONSTRAINT FOREIGN KEY(Reservation_number) references Reservation(Reservation_number) on delete cascade
);

CREATE TABLE hasPassengerReservation (
Reservation_number INTEGER NOT NULL,
Passport_number INTEGER NOT NULL,
Ticket_number INTEGER,
CONSTRAINT PRIMARY KEY(Reservation_number, Passport_number),
CONSTRAINT FOREIGN KEY(Reservation_number) references Reservation(Reservation_number),
CONSTRAINT FOREIGN KEY(Passport_number) references Passenger(Passport_number)
);

CREATE TABLE yearlyProfitFactor (
Year INTEGER NOT NULL,
Profitfactor DOUBLE NOT NULL,
CONSTRAINT PRIMARY KEY(Year)
);

CREATE TABLE weeklyProfitFactor (
Day VARCHAR(10) NOT NULL,
Year INTEGER NOT NULL,
Weekdayfactor DOUBLE NOT NULL,
CONSTRAINT PRIMARY KEY(Day, Year)
);

DELIMITER &&
CREATE PROCEDURE addYear(IN year INTEGER, IN factor DOUBLE)
BEGIN
	INSERT INTO yearlyProfitFactor(Year, Profitfactor) VALUES(year, factor);
END &&
DELIMITER ;

DELIMITER &&
CREATE PROCEDURE addDay(IN year INTEGER, IN day VARCHAR(10), IN factor DOUBLE)
BEGIN
	INSERT INTO weeklyProfitFactor(Year, Day, Weekdayfactor) VALUES(year, day, factor);
END &&
DELIMITER ;

DELIMITER &&
CREATE PROCEDURE addDestination(IN airport_code VARCHAR(3), IN name VARCHAR(30), IN country VARCHAR(30))
BEGIN
	INSERT INTO Airport(Airport_code, Airport_name, Country) VALUES(airport_code, name, country);
END &&
DELIMITER ;

DELIMITER &&
CREATE PROCEDURE addRoute(IN departure_airport_code VARCHAR(3), IN arrival_airport_code VARCHAR(3), IN year INTEGER, IN routeprice DOUBLE)
BEGIN
	INSERT INTO Route(Departure_airport_code, Arrival_airport_code, Year, Route_price) VALUES(departure_airport_code, arrival_airport_code, year, routeprice);
END &&
DELIMITER ;

DELIMITER &&

CREATE PROCEDURE addFlight(IN departure_airport_code VARCHAR(3), IN arrival_airport_code VARCHAR(3), IN year INTEGER, IN day VARCHAR(10), IN departure_time TIME)
BEGIN
	DECLARE week INTEGER;
    SET week = 1;

    SELECT Route.Route_id INTO @rid FROM Route WHERE Route.Departure_airport_code = departure_airport_code and Route.Arrival_airport_code = arrival_airport_code and Route.Year = year;
	INSERT INTO weeklySchedule(Day, Year, Departure_time, Route_id) VALUES(day, year, departure_time, @rid);
    SELECT ID INTO @wsid FROM weeklySchedule WHERE weeklySchedule.Day = day and weeklySchedule.Year = year and weeklySchedule.Departure_time = departure_time and weeklySchedule.Route_id = @rid;

WHILE week <= 52 DO
		INSERT INTO Flight(Year, Week, Weekly_schedule_id) VALUES(year, week, @wsid);
		SET week = week + 1;
END WHILE;

END &&
DELIMITER ;

DELIMITER &&
CREATE FUNCTION calculateFreeSeats(flightnumber INTEGER)
RETURNS INTEGER

BEGIN
    DECLARE booked_seats INTEGER;
    DECLARE free_seats INTEGER;

	SET booked_seats = (SELECT COUNT(hasPassengerReservation.Ticket_number) FROM Reservation INNER JOIN hasPassengerReservation ON hasPassengerReservation.Reservation_number = Reservation.Reservation_number WHERE Reservation.Flightnumber = flightnumber);
    SET free_seats = 40 - booked_seats;

    RETURN free_seats;
END &&
DELIMITER ;

DELIMITER &&
CREATE FUNCTION calculatePrice(flightnumber INTEGER)
RETURNS DOUBLE

BEGIN
	DECLARE total_price DOUBLE;
	DECLARE routeprice DOUBLE;
    DECLARE wid INTEGER;
    DECLARE day VARCHAR(10);
    DECLARE year INTEGER;
    DECLARE weekdayfactor DOUBLE;
    DECLARE profitfactor DOUBLE;
    DECLARE booked_passenger INTEGER;

	SELECT Flight.Weekly_schedule_id into wid FROM Flight WHERE Flight.Flightnumber = flightnumber;
    SET routeprice = (SELECT Route.Route_price FROM weeklySchedule, Route WHERE weeklySchedule.ID = wid AND weeklySchedule.Route_id = Route.Route_id);

	SELECT weeklySchedule.Day into day FROM weeklySchedule WHERE weeklySchedule.ID = wid;
    SELECT weeklySchedule.Year into year FROM weeklySchedule WHERE weeklySchedule.ID = wid;
    SELECT weeklyProfitFactor.Weekdayfactor into weekdayfactor FROM weeklyProfitFactor WHERE weeklyProfitFactor.Year = year AND weeklyProfitFactor.Day = day;

    SELECT yearlyProfitFactor.Profitfactor into profitfactor FROM yearlyProfitFactor WHERE yearlyProfitFactor.Year = year;
    SET booked_passenger = 40 - calculateFreeSeats(flightnumber);

    #SET total_price = routeprice * weekdayfactor *  (booked_passenger + 1) /40 * profitfactor; # WRONG
    #SET total_price = routeprice * weekdayfactor * ((booked_passenger + 1)/40) * profitfactor; # ALSO WRONG
    SET total_price = routeprice * weekdayfactor * profitfactor * ((booked_passenger + 1)/40); # RIGHT

	RETURN total_price;
END &&

CREATE FUNCTION uniqueRandomNumber()
RETURNS INTEGER
BEGIN
	DECLARE random_number INTEGER;
	DECLARE is_used INTEGER;
	SET random_number = CAST(RAND() * 1000000 AS signed INTEGER);
    SELECT COUNT(hasPassengerReservation.Reservation_number) into is_used FROM hasPassengerReservation WHERE hasPassengerReservation.Ticket_number = random_number;

    WHILE is_used > 0 DO
		SET random_number = CAST(RAND() * 1000000 AS signed INTEGER);
		SELECT COUNT(hasPassengerReservation.Reservation_number) into is_used FROM hasPassengerReservation WHERE hasPassengerReservation.Ticket_number = random_number;
	END WHILE;
	RETURN random_number;
END &&

CREATE TRIGGER generateTicketNumber
AFTER INSERT ON Payment
FOR EACH ROW
BEGIN
    UPDATE hasPassengerReservation
    SET hasPassengerReservation.Ticket_number = uniqueRandomNumber()
    WHERE hasPassengerReservation.Reservation_number = NEW.Reservation_number;

END &&

CREATE PROCEDURE addReservation(IN departure_airport_code VARCHAR(3), IN arrival_airport_code VARCHAR(3), IN year INTEGER,IN week INTEGER, IN day VARCHAR(10), IN time TIME, IN number_of_passengers INTEGER, OUT output_reservation_nr INTEGER)
`whole_proc`:
BEGIN
DECLARE fnumber INTEGER;
DECLARE number_flights INTEGER;
DECLARE r_no INTEGER;

SELECT Route.Route_id into @rid FROM Route WHERE Route.Departure_airport_code = departure_airport_code AND Route.Arrival_airport_code = arrival_airport_code AND Route.Year = year;
SET number_flights = (SELECT Flight.flightnumber FROM Flight, weeklySchedule WHERE weeklySchedule.Route_id = @rid AND weeklySchedule.Day = day AND Flight.Week = week AND weeklySchedule.Departure_time = time AND Flight.Weekly_schedule_id = weeklySchedule.ID);

IF number_flights is NULL THEN
	SELECT "There exists no flight for the given route, date and time" as "Message";
	LEAVE `whole_proc`;
END IF;

SET fnumber = (SELECT Flight.Flightnumber FROM Flight, weeklySchedule WHERE weeklySchedule.Day = day AND Flight.Week = week AND weeklySchedule.Departure_time = time AND Flight.Weekly_schedule_id = weeklySchedule.ID);

IF calculateFreeSeats(@fnumber) >= number_of_passengers THEN
    SET r_no = (SELECT COUNT(Reservation.Reservation_number) FROM Reservation) +1;
	INSERT INTO Reservation(Reservation_number, Number_of_passengers, Flightnumber) VALUES(r_no, number_of_passengers, fnumber);
	SET output_reservation_nr = r_no;

ELSE
	SELECT "There are not enough seats available on the chosen flight" as "Message";

END IF;
END &&

DELIMITER ;

DELIMITER &&
CREATE PROCEDURE addPassenger(IN reservation_nr INTEGER, IN passport_number INTEGER, IN name VARCHAR(30))
`whole_proc`:
BEGIN
DECLARE rn INTEGER;
DECLARE is_paid INTEGER;
DECLARE no_passport_number INTEGER;

SET rn = (SELECT COUNT(Reservation.Reservation_number) FROM Reservation WHERE Reservation.Reservation_number = reservation_nr);

IF rn = 0 THEN
	SELECT "The given reservation number does not exist" as "Message";
    LEAVE `whole_proc`;
END IF;

SET rn = (SELECT Reservation.Reservation_number FROM Reservation WHERE Reservation.Reservation_number = reservation_nr);
SET is_paid = (SELECT COUNT(Payment.Reservation_number) FROM Payment WHERE Payment.reservation_number = rn);

# Must be unpaid to insert new passengers for a reservation
IF is_paid = 0 THEN
    SET no_passport_number = (SELECT COUNT(Passenger.Passport_number) FROM Passenger WHERE Passenger.Passport_number = passport_number);
    # Do not add new a passenger who is already in the db
    IF no_passport_number = 0 THEN
		INSERT INTO Passenger(Passport_number, Name) VALUES(passport_number, name);
	END IF;

	INSERT INTO hasPassengerReservation(Passport_number, Reservation_number) VALUES(passport_number, rn);
	LEAVE `whole_proc`;
END IF;

SELECT "The booking has already been payed and no futher passengers can be added" as "Message";

END &&
DELIMITER ;

DELIMITER &&
CREATE PROCEDURE addContact(IN reservation_nr INTEGER, IN passport_number INTEGER, IN email VARCHAR(30), IN phone BIGINT)
`whole_proc`:
BEGIN
DECLARE rn INTEGER;

SET rn = (SELECT COUNT(Reservation.Reservation_number) FROM Reservation WHERE Reservation.Reservation_number = reservation_nr);
IF rn = 0 THEN
	SELECT "The given reservation number does not exist" as "Message";
    LEAVE `whole_proc`;
END IF;

SET rn = (SELECT COUNT(hasPassengerReservation.Reservation_number) FROM hasPassengerReservation WHERE hasPassengerReservation.Reservation_number = reservation_nr AND hasPassengerReservation.Passport_number = passport_number);
IF rn = 0 THEN
	SELECT "The person is not a passenger of the reservation" as "Message";
    LEAVE `whole_proc`;
END IF;

SET rn = (SELECT Reservation.Reservation_number FROM Reservation WHERE Reservation.Reservation_number = reservation_nr);
UPDATE Reservation SET Reservation.Email = email, Reservation.Phone_number = phone, Reservation.Passport_number = passport_number WHERE Reservation.Reservation_number = rn; ### LA TILL PPN!!!

END &&
DELIMITER ;

DELIMITER &&
CREATE PROCEDURE addPayment(IN reservation_nr INTEGER, IN cardholder_name VARCHAR(30), IN credit_card_number BIGINT)
`whole_proc`:
BEGIN
DECLARE rn INTEGER;
DECLARE email_counter INTEGER;
DECLARE fn INTEGER;
DECLARE no_p INTEGER;
DECLARE price DOUBLE;

SET rn = (SELECT COUNT(Reservation.Reservation_number) FROM Reservation WHERE Reservation.Reservation_number = reservation_nr);
IF rn = 0 THEN
	SELECT "The given reservation number does not exist" as "Message";
    LEAVE `whole_proc`;
END IF;

SET rn = (SELECT Reservation.Reservation_number FROM Reservation WHERE Reservation.Reservation_number = reservation_nr);
SET email_counter = (SELECT COUNT(Reservation.Email) FROM Reservation WHERE Reservation.Reservation_number = rn);

IF email_counter = 0 THEN
	SELECT "The reservation has no contact yet" as "Message";
	LEAVE `whole_proc`;
END IF;

SET fn = (SELECT Reservation.Flightnumber FROM Reservation WHERE Reservation.Reservation_number = rn);

SET no_p = (SELECT COUNT(hasPassengerReservation.Passport_number) FROM hasPassengerReservation WHERE hasPassengerReservation.Reservation_number = reservation_nr);

IF calculateFreeSeats(fn) < no_p THEN
	SELECT "There are not enough seats available on the flight anymore, deleting reservation" as "Message";
	LEAVE `whole_proc`;
END IF;

/*SELECT SLEEP(5); # Concurrency testing*/

SET price = no_p * (SELECT calculatePrice(fn));

INSERT INTO Payment(Creditcard_number, Creditcard_holder, Reservation_number, Total_price) VALUES (credit_card_number, cardholder_name, reservation_nr, price);

END &&
DELIMITER ;

CREATE VIEW allFlights
AS
(SELECT
	(SELECT Airport.Airport_name from Airport where Airport.Airport_code = Departure_airport_code) AS departure_city_name,
    (SELECT Airport.Airport_name from Airport where Airport.Airport_code = Arrival_airport_code) AS destination_city_name,
    Departure_time AS departure_time,
    Day AS departure_day,
    Week AS departure_week,
    f.Year AS departure_year,
    calculateFreeSeats(Flightnumber) AS nr_of_free_seats,
    calculatePrice(Flightnumber) AS current_price_per_seat
FROM Flight f, weeklySchedule w, Route r, Airport a1, Airport a2
WHERE f.Weekly_schedule_id = w.ID AND r.Route_id = w.Route_id
AND a1.Airport_code = r.Departure_airport_code AND a2.Airport_code = r.Arrival_airport_code);
