SELECT 
	dataset, epsilon, mu, delta, round(avg(timetest)::numeric,3) as time, flocks, substring(tag from 1 for 3) as tag 
FROM
	test 
GROUP BY 
	dataset, epsilon, mu, delta, flocks, substring(tag from 1 for 3) 
ORDER BY 
	dataset, tag, epsilon, mu, delta;
