SELECT bfe.members, bfe.started, bfe.ended, lcm.members, lcm.started, lcm.ended FROM (
SELECT
	members, min(started) AS started, max(ended) AS ended 
FROM	
	flockbfe
GROUP BY
	1
order by
	2,1) AS bfe 

LEFT JOIN (
SELECT
	members, started, ended 
FROM	
	flocklcm
order by
	2,1) AS lcm

USING
	(members,started, ended)
WHERE
	lcm.members is NULL

