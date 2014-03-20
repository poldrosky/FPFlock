#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  bfev1.py
#  
#  Copyright 2014 Omar Ernesto Cabrera Rosero <omarcabrera@udenar.edu.co>
#  
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#  
#  

import csv
import scipy.spatial as ss
import random
import math
import sys

epsilon1 = 200
timestamp = 100
pointsTimestamp = int(sys.argv[1]) 
m = math.ceil(math.sqrt(pointsTimestamp))
flocks = int(sys.argv[2])
output = csv.writer(open('SJ'+str(pointsTimestamp)+'T'+'100t'+str(flocks)+'f'+'.csv', 'w', newline=''), delimiter='\t')
print('SJ'+str(pointsTimestamp)+'T'+'100t'+str(flocks)+'f'+'.csv')

random.seed(666)

def matrix():
	coordinate = []
	x = 100
	y = 100
	for i in range(m):
		for j in range(m):
			coordinate.append([x,y])
			x += epsilon1
		x = 100
		y += epsilon1
	
	return coordinate
	
def randomPoints(amount, min, max):
	points = []
	
	while len(points) < amount:
		point = random.randint(min, max)
		
		if not point in points:
			points.append(point)
		
	return points


for time in range(timestamp):
	points = randomPoints(pointsTimestamp, 1, pointsTimestamp)
	grid = matrix()	
	for i in range(len(points)):
		output.writerow([points[i], time, grid[i][0], grid[i][1]])


dataset = csv.reader(open('SJ'+str(pointsTimestamp)+'T'+'100t'+str(flocks)+'f'+'.csv', 'r'),delimiter='\t')


points = randomPoints(flocks, 1, pointsTimestamp)

times = []

while len(times) < flocks:
	a = random.randint(1, 100)
	b = random.randint(1, 100)
	if a < b and (b-a)>=3 and (b-a)<=20:
		times.append([a,b])
	elif a>b and (a-b)>=3 and (b-a)<=20:
		times.append([b,a])

aux = pointsTimestamp + 1
vector=[]
for time, points in zip(times,points):
	vector.append([time[0], time[1],points])

print(len(vector))
print(vector)

for i in vector:
	for j in range(i[0],i[1]+1):
		key = aux
		for id, time, x, y in dataset:
			if(i[2] == int(id) and j == int(time)):
				for au in range(3):
					output.writerow([key, j, int(x)+random.randint(-10, 10), int(y)+random.randint(-10, 10)])
					key += 1
		dataset = csv.reader(open('SJ'+str(pointsTimestamp)+'T'+'100t'+str(flocks)+'f'+'.csv', 'r'),delimiter='\t')
		key += 1
	aux = key + 1			
				
