#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  generatorData.py
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

import pdbc
import csv
import random
import math
import sys
import os
import io

epsilon1 = 200
pointsTimestamp = int(sys.argv[1]) 
m = math.ceil(math.sqrt(pointsTimestamp))
flocks = int(sys.argv[2])
timestamp = 100

filename = 'SJ{0}T{1}t{2}f.csv'.format(pointsTimestamp,timestamp,flocks)

os.system('rm {0}'.format(filename))

output = open(filename, 'w', newline='')
writer = csv.writer(output, delimiter='\t')

print(filename)

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
		writer.writerow([points[i], time, grid[i][0], grid[i][1]])

dataset = output
output.close()
os.system('cp {0} aux.csv'.format(filename)) 

output = open(filename, 'a', newline='')
writer = csv.writer(output, delimiter='\t')


dataset = csv.reader(open('aux.csv', 'r'),delimiter='\t')

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

fid = 1
vector=[]

c = {}

for time, point in zip(times,points):
	vector.append([time[0], time[1],point])
	c[point] = set()
	c[point].add(point)

aux = pointsTimestamp + 1

for i in vector:
	for j in range(i[0],i[1]+1):
		key = aux
		for id, time, x, y in dataset:
			if(i[2] == int(id) and j == int(time)):
				for au in range(3):
					c[i[2]].add(key)					
					writer.writerow([key, j, int(x)+random.randint(-10, 10), int(y)+random.randint(-10, 10)])
					key += 1
		dataset = csv.reader(open('aux.csv', 'r'),delimiter='\t')
	aux = key			

stdin = []

for i in vector:
	b = list(c[i[2]])			
	b.sort()
	stdin.append('{0}\t{1}\t{2}\t{3}'.format(fid, i[0], i[1], b))
	fid += 1

table = ('flock{0}real'.format(filename)).replace('.csv','')

db = pdbc.DBConnector()
db.resetTable(table)
stdin = '\n'.join(stdin)
#print(stdin)
db.copyToTable(table,io.StringIO(stdin))
