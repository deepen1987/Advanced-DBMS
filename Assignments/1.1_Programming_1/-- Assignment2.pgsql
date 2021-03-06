-- Question 1
select * from membership;

alter table membership
add dvdattime integer;

update membership
set dvdattime = cast(substring( membershiptype from 1 for 1) as integer);

-- Question 2

select * from rental;

CREATE SEQUENCE IF NOT EXISTS unknownSequence
	AS integer
	INCREMENT BY 1
	START WITH 11
	OWNED BY rental.rentalid;
	
INSERT INTO 
	rental (RentalId,MemberId,DVDId,RentalRequestDate)
VALUES
	(nextval('rentalSequence'),15,1,'2020/02/29');
	
INSERT INTO 
	rental (RentalId,MemberId,DVDId,RentalRequestDate)
VALUES
	(nextval('rentalSequence'),15,2,'2020/05/29');
	
-- Question 3
DROP TABLE IF EXISTS dvdreview;

CREATE TABLE dvdreview (
	dvdid numeric(16,0) NOT NULL,
	memberid numeric(12,0) NOT NULL,
	starvalue integer NOT NULL CHECK (starvalue > 0 AND starvalue < 6),
	reviewdate DATE NOT NULL DEFAULT CURRENT_DATE,
	comments varchar(400) ,
	CONSTRAINT dvdreview_dvdid_memberid_pk PRIMARY KEY (dvdid, memberid),
	CONSTRAINT dvdreview_dvdid_fk FOREIGN KEY (dvdid)
		REFERENCES public.dvd (dvdid) MATCH SIMPLE
		ON UPDATE NO ACTION
		ON DELETE NO ACTION,
	CONSTRAINT dvdreview_memberid_fk FOREIGN KEY (memberid)
		REFERENCES public.member (memberid) MATCH SIMPLE
		ON UPDATE NO ACTION
		ON DELETE NO ACTION
);

SELECT * FROM dvdreview;
commit;
-- Question 4
INSERT INTO dvdreview (dvdid, memberid, starvalue, reviewdate, comments)
VALUES (4, 1, 4, DEFAULT, 'good movie');
INSERT INTO dvdreview (dvdid, memberid, starvalue, reviewdate, comments)
VALUES (6, 1, 4, DEFAULT, 'didn''t liked the movie a lot');
INSERT INTO dvdreview (dvdid, memberid, starvalue, reviewdate, comments)
VALUES (5, 5, 4, '2021-03-03', 'good movie');

SELECT * FROM dvdreview;
SELECT * FROM dvd

CREATE VIEW member_review AS
SELECT 
	CONCAT(m.memberfirstname, ' ', m.memberlastname) AS fullname,
	d.dvdtitle,
	r.starvalue,
	r.reviewdate,
	r.comments
FROM dvdreview r
JOIN member m on r.memberid = m.memberid
JOIN dvd d on r.dvdid = d.dvdid;

SELECT * FROM member_review
WHERE dvdtitle = 'The Sixth Sense';

INSERT INTO dvdreview (dvdid, memberid, starvalue, reviewdate, comments)
VALUES (5, 1, 8, DEFAULT, 'good movie');

UPDATE dvdreview 
SET starvalue = 2 
WHERE dvdid = 6 AND memberid = 1;

DELETE FROM dvdreview
WHERE dvdid = 6 AND memberid = 1;

-- Question 6
SELECT 
	d.dvdtitle,
	g.genrename,
	r.ratingname,
	CONCAT (mp.personfirstname, ' ', mp.personlastname) as name,
	role.rolename
FROM dvd d
JOIN rating r ON d.ratingid = r.ratingid
JOIN genre g ON d.genreid = g.genreid
JOIN moviepersonrole mpr ON d.dvdid = mpr.dvdid
JOIN movieperson mp ON mpr.personid = mp.personid
JOIN role ON mpr.roleid = role.roleid
WHERE g.genrename = 'Action';

-- Question 7
select rentalreturneddate from rental where rentalid = 4

select * from movieperson

SELECT
	CONCAT(m.memberfirstname, ' ', m.memberlastname) AS memberfullname,
	d.dvdtitle,
	g.genrename,
	rating.ratingname,
	roles.directorfullname
FROM member m
JOIN rental r ON m.memberid = r.memberid
JOIN dvd d ON r.dvdid = d.dvdid
JOIN rating rating ON d.ratingid = rating.ratingid
JOIN genre g ON d.genreid = g.genreid
JOIN 
	(
		SELECT 
			d.dvdid,
			CONCAT (mp.personfirstname, ' ', mp.personlastname) AS directorfullname
		FROM movieperson mp
		JOIN moviepersonrole mpr ON mp.personid = mpr.personid and mpr.roleid = 3
		RIGHT JOIN dvd d ON mpr.dvdid = d.dvdid
	) AS roles ON d.dvdid = roles.dvdid
WHERE r.rentalshippeddate IS NOT NULL AND r.rentalreturneddate IS NULL;

-- Otherway of writing it.

WITH roles AS
	(
		SELECT 
			d.dvdid,
			CONCAT (mp.personfirstname, ' ', mp.personlastname) AS directorfullname
		FROM movieperson mp
		JOIN moviepersonrole mpr ON mp.personid = mpr.personid and mpr.roleid = 3
		RIGHT JOIN dvd d ON mpr.dvdid = d.dvdid 
	)
SELECT
	CONCAT(m.memberfirstname, ' ', m.memberlastname) AS memberfullname,
	d.dvdtitle,
	g.genrename,
	rating.ratingname,
	roles.directorfullname
FROM member m
JOIN rental r ON m.memberid = r.memberid
JOIN dvd d ON r.dvdid = d.dvdid
JOIN rating rating ON d.ratingid = rating.ratingid
JOIN genre g ON d.genreid = g.genreid
JOIN roles ON d.dvdid = roles.dvdid
WHERE r.rentalshippeddate IS NOT NULL AND r.rentalreturneddate IS NULL;

-- Question8

WITH ranklist AS
(
	SELECT 
		*,
	RANK() OVER (
		PARTITION BY r1.memberid
		ORDER BY r1.rentalid desc
	) AS ranks
	FROM rental r1
)
SELECT
	CONCAT(m.memberfirstname, ' ', m.memberlastname) AS customername,
	rl.dvdid,
	d.dvdtitle,
	g.genrename,
	r.ratingname,
	rl.rentalrequestdate
FROM ranklist rl
JOIN member m ON rl.memberid = m.memberid and rl.ranks = 1
JOIN dvd d ON rl.dvdid = d.dvdid
JOIN genre g ON d.genreid = g.genreid
JOIN rating r ON d.ratingid = r.ratingid;
					
-- Question9
SELECT 
	d.dvdtitle,
	g.genrename,
	rating.ratingname,
	COUNT(r.dvdid) AS totalnumberofrentals
FROM rental r
JOIN dvd d ON r.dvdid = d.dvdid
JOIN genre g ON d.genreid = g.genreid
JOIN rating ON d.ratingid = rating.ratingid
GROUP BY r.dvdid, d.dvdtitle, g.genrename, rating.ratingname

-- Question10
SELECT
	r.dvdid,
	d.dvdtitle,
	g.genrename,
	rating.ratingname,
	AVG(DATE_PART('day', rentalreturneddate - rentalshippeddate)) AS avgdaycount
FROM rental r
JOIN dvd d ON r.dvdid = d.dvdid
JOIN genre g ON d.genreid = g.genreid
JOIN rating ON d.ratingid = rating.ratingid
WHERE rentalshippeddate IS NOT NULL
GROUP BY r.dvdid, d.dvdtitle, g.genrename, rating.ratingname
ORDER BY r.dvdid;

select
	dvdid,
	DATE_PART('day', rentalreturneddate - rentalshippeddate)
from rental
where rentalshippeddate IS NOT NULL

select * from rental

UPDATE rental
SET rentalreturneddate = NULL
WHERE rentalid = 4;
UPDATE rental
SET rentalreturneddate = NULL
WHERE rentalid = 5;
UPDATE rental
SET rentalreturneddate = NULL
WHERE rentalid = 7;
UPDATE rental
SET rentalreturneddate = NULL
WHERE rentalid = 8;
UPDATE rental
SET rentalreturneddate = NULL
WHERE rentalid = 9;
UPDATE rental
SET rentalreturneddate = NULL
WHERE rentalid = 11;

-- Question11

select 
	DATE_PART('year', CURRENT_DATE) - DATE_PART('year', rentalrequestdate),
	*
from rental

-- One way of doing it
SELECT 
	g.genrename,
	COUNT(d.genreid) AS totalnumberofrentals
FROM rental r
JOIN dvd d ON r.dvdid = d.dvdid
JOIN genre g ON d.genreid = g.genreid
WHERE DATE_PART('year', CURRENT_DATE) - DATE_PART('year', rentalrequestdate) < 5
GROUP BY g.genrename, d.genreid
ORDER BY totalnumberofrentals DESC
LIMIT 3

-- Second way of doing it
WITH totalrentalsdvd AS
(
	SELECT 
		r.dvdid
	FROM rental r
	WHERE DATE_PART('year', CURRENT_DATE) - DATE_PART('year', rentalrequestdate) < 5
)
SELECT 
	g.genrename,
	COUNT(d.genreid) AS totalnumberofrentals
FROM totalrentalsdvd trd
JOIN dvd d ON trd.dvdid = d.dvdid
JOIN genre g ON d.genreid = g.genreid
GROUP BY g.genrename, d.genreid
ORDER BY totalnumberofrentals DESC
LIMIT 3

-- Question12
select * from membership

select * from member

SELECT
	ms.membershiptype,
	COUNT(ms.membershipid) AS totalrentedmovie,
	RANK() OVER	(
		ORDER BY COUNT(ms.membershipid) DESC
				) AS ranks
FROM rental r
JOIN member m ON r.memberid = m.memberid
JOIN membership ms ON m.membershipid = ms.membershipid
GROUP BY ms.membershiptype;

SELECT
	ms.membershiptype,
	COUNT(ms.membershipid) AS totalrentedmovie,
	DENSE_RANK() OVER	(
		ORDER BY COUNT(ms.membershipid) DESC
				) AS ranks
FROM rental r
JOIN member m ON r.memberid = m.memberid
JOIN membership ms ON m.membershipid = ms.membershipid
GROUP BY ms.membershiptype;

-- Question13

WITH genredetail AS
(
	SELECT 
		d.dvdid,
		g.genrename
	FROM dvd d
	JOIN genre g ON d.genreid = g.genreid
)
SELECT
	gd.genrename,
	ms.membershiptype,
	COUNT(ms.membershipid) AS totalrentedmovie
FROM rental r
JOIN member m ON r.memberid = m.memberid
JOIN membership ms ON m.membershipid = ms.membershipid
JOIN genredetail gd ON r.dvdid = gd.dvdid
GROUP BY 
	ROLLUP(gd.genrename, ms.membershiptype)
ORDER BY gd.genrename;

-- Question14
select * from rental

UPDATE
	rental
SET
	rentalrequestdate = '2020-06-20',
	rentalshippeddate = '2020-06-20',
	rentalreturneddate = '2020-06-21'
WHERE rentalid IN (7);


CREATE EXTENSION tablefunc;

SELECT
	*
FROM crosstab(
		'WITH genredvd AS
		(
			SELECT
				g.genrename,
				d.dvdid
			FROM dvd d
			JOIN genre g ON d.genreid = g.genreid
		)
		SELECT
			EXTRACT(YEAR FROM r.rentalrequestdate) AS year,
			gd.genrename,
			COUNT(r.dvdid) AS totalrenteddvd
		FROM rental r
		JOIN genredvd gd ON r.dvdid = gd.dvdid
		GROUP BY year, gd.genrename
		ORDER BY year, gd.genrename'
) AS finalresult	(
						year double precision, 
						Western BIGINT, 
						Drama BIGINT, 
						Horror BIGINT, 
						Comedy BIGINT, 
						Action BIGINT
					);

-- Question15

WITH genredvd AS
(
	SELECT
		g.genrename,
		d.dvdid
	FROM dvd d
	JOIN genre g ON d.genreid = g.genreid
)
SELECT
	gd.genrename, 
	TO_CHAR(r.rentalrequestdate, 'Month') AS month,
	EXTRACT(YEAR FROM r.rentalrequestdate) AS year,
	COUNT(r.dvdid) AS totalrenteddvd
FROM rental r
JOIN genredvd gd ON r.dvdid = gd.dvdid
WHERE DATE_PART('year', CURRENT_DATE) - DATE_PART('year', rentalrequestdate) < 3
GROUP BY gd.genrename, month, year
ORDER BY year, month, gd.genrename;