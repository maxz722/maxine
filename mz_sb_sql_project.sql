/* Welcome to the SQL mini project. For this project, you will use
Springboard' online SQL platform, which you can log into through the
following link:

https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

Note that, if you need to, you can also download these tables locally.

In the mini project, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */



/* Q1: Some of the facilities charge a fee to members, but some do not.
Please list the names of the facilities that do. */

SELECT name
FROM Facilities
GROUP BY 1
HAVING SUM( membercost ) > 0
ORDER BY 1
-- massage room 1 & 2, squash court, tennis court 1 & 2 


/* Q2: How many facilities do not charge a fee to members? */

SELECT count(distinct name) as name_count 
FROM 
(
SELECT name
FROM Facilities
GROUP BY 1
HAVING SUM( membercost ) =0
ORDER BY 1
) a 


/* Q3: How can you produce a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost?
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT
	facid,
	name,
	SUM(membercost) as member_cost,
	SUM(monthlymaintenance) as monthly_maintenance,
	--SUM(membercost)/SUM(monthlymaintenance) as fee_perc 
FROM Facilities 
GROUP BY 1,2
HAVING SUM(membercost) > 0 
AND (SUM(membercost)/SUM(monthlymaintenance)) < 0.2



/* Q4: How can you retrieve the details of facilities with ID 1 and 5?
Write the query without using the OR operator. */

SELECT * 
FROM Facilities
WHERE facid IN (1,5)



/* Q5: How can you produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100? Return the name and monthly maintenance of the facilities
in question. */

-- Option A: when the fields are all unique
SELECT name, 
	   CASE WHEN monthlymaintenance > 100 THEN 'expensive'
	   		ELSE 'cheap' END AS label,
	   monthlymaintenance
FROM Facilities
GROUP BY 1,2,3 
ORDER BY 3


-- Option B: when the fields repeat 
SELECT name,
	   monthly_maintenance,
	   CASE WHEN label = 0 THEN 'cheap' ELSE 'expensive' END AS label
FROM ( 	
SELECT
	name,
	SUM(monthlymaintenance) as monthly_maintenance,
	SUM(CASE WHEN monthlymaintenance > 100 THEN 1 ELSE 0 END) AS label 
FROM Facilities
GROUP BY 1 
) a
ORDER BY 3 

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Do not use the LIMIT clause for your solution. */


SELECT firstname,
	   surname,
	   -- joindate
FROM Members
WHERE joindate = (SELECT max(joindate) FROM Members)
#2012-09-26 18:08:45



/* Q7: How can you produce a list of all members who have used a tennis court?
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */



SELECT 
	concat(firstname," ", surname) as member_name,
	facility_name as facility
FROM Members mm
JOIN (
SELECT memid, fc.name as facility_name
FROM Bookings bk
JOIN Facilities fc 
ON bk.facid = fc.facid 
WHERE lower(fc.name) like '%tennis court%'
GROUP BY 1,2) sq
ON mm.memid = sq.memid
ORDER BY 1
-- name appears twice because the member used both tennis courts 



/* Q8: How can you produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30? Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */


SELECT fc.name as facility_name,
	   CONCAT(mm.firstname, " ", mm.surname) as member_name,
	   CASE WHEN bk.memid = 0 THEN fc.guestcost * SUM(slots) 
			ELSE fc.membercost * SUM(slots) END AS cost
FROM Bookings bk
JOIN Facilities fc
ON bk.facid = fc.facid
JOIN Members mm
ON bk.memid = mm.memid 
WHERE LEFT( starttime, 10 ) = '2012-09-14'
GROUP BY 1,2
HAVING cost > 30
ORDER BY cost DESC


/* Q9: This time, produce the same result as in Q8, but using a subquery. */


SELECT  
 		fc.name as facility_name,
 		concat(firstname, " ", surname) as member_name,
		CASE WHEN bk.memid = 0 THEN num_slots * guestcost 
			ELSE num_slots * membercost END AS cost
FROM Facilities fc 
JOIN 
(
SELECT facid,
	   memid,
	   SUM(slots) as num_slots 
FROM Bookings
WHERE LEFT( starttime, 10 ) = '2012-09-14'
GROUP BY 1,2
) bk 
ON fc.facid = bk.facid
JOIN Members mm
ON bk.memid = mm.memid
WHERE CASE WHEN bk.memid = 0 THEN num_slots * guestcost 
			ELSE num_slots * membercost END > 30
ORDER BY cost desc



/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */


SELECT fc.name as facility_name,
	   CASE WHEN bk.memid = 0 THEN fc.guestcost * SUM(slots) 
			ELSE fc.membercost * SUM(slots) END AS revenue
FROM Bookings bk
JOIN Facilities fc
ON bk.facid = fc.facid
JOIN Members mm
ON bk.memid = mm.memid 
GROUP BY 1
HAVING revenue < 1000
ORDER BY revenue DESC
-- $0? 

-- To Double-Check

SELECT facility_name,
	   CASE WHEN guest_label = 0 THEN num_slots * guestcost 
			ELSE num_slots * membercost 
		END AS revenue 
FROM 
(
SELECT  bk.facid as facid, 
		fc.name as facility_name,
		CASE WHEN bk.memid = 0 then 1 else 0 end as guest_label,
		fc.guestcost,
		fc.membercost,
		sum(slots) as num_slots
FROM Bookings bk
JOIN Facilities fc
ON bk.facid = fc.facid
GROUP BY 1,2,3,4,5
) a
where CASE WHEN guest_label = 0 THEN num_slots * guestcost 
			ELSE num_slots * membercost 
		END < 1000
order by 2 desc


