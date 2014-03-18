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

epsilon1 = 200
epsilon2 = 50
timestamp = 100
points = 100
output = csv.writer(open('syntheticdata.csv', 'w', newline=''), delimiter='\t')

def matrix():
	table= [ [ 0 for i in range(100) ] for j in range(100) ]
	coordinate = []
	x = 100
	y = 100
	for i in range(35):
		for j in range(35):
			table[i][j]= [x,y]
			x += epsilon1
		x = 100
		y += epsilon1
	
	for i in range(35):
		for j in range(35):
			coordinate.append(table[i][j])
			
	return coordinate
	
def randomPoints(cantidad, min, max):
    numeros = set()
 
    if max < min:
        min, max = max, min
 
    if cantidad > (max-min):
        cantidad = max - min
 
    while len(numeros) < cantidad:
        numeros.add(random.randint(min, max))
	
	return numeros

print(randomPoints(10, 1, 10))			
	
for time in range(timestamp):
	for i, j in zip(randomPoints(1000,1,1000), matrix()):
		output.writerow([i,time,j])
		


	
	


