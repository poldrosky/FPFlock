#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  lcmFlock.py
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

import bfe
import time
import csv
import os
import pdbc
import io

def getTransactions(points, timestamp, maximalDisks):
	for maximal in maximalDisks:
		for member in maximalDisks[maximal].members:
			if not member  in traj.keys():
				traj[member]= []
				traj[member].append(maximalDisks[maximal].id)
			else:
				traj[member].append(maximalDisks[maximal].id)
	return traj
	

def flocks(output1, totalMaximalDisks, keyFlock):
	lines = output1.readlines()
	for line in lines:
		lineSplit = line.split(' ')
		array = list(map(int,lineSplit[:-1]))
		array.sort()
		if len(array) < bfe.delta:
			continue
		frecuency = int(lineSplit[-1].replace('(','').replace(')',''))
		members = totalMaximalDisks[int(str(array[0]))].members
		begin = totalMaximalDisks[int(str(array[0]))].timestamp
		end = begin
		for element in range(1,len(array)):
			now = totalMaximalDisks[int(str(array[element]))].timestamp
			if(now == end + 1 or now == end):
				if(now == end + 1):
					members = members.intersection(totalMaximalDisks[int(str(array[element]))].members)
				end = now
				
			elif end-begin >= bfe.delta - 1:
				b = list(members)
				b.sort()
				stdin.append('{0}\t{1}\t{2}\t{3}'.format(keyFlock, begin, end, b))
				keyFlock += 1
				begin = end = now
				
			else: 
				begin = end = now
				
		if end-begin >= bfe.delta - 1:
			b = list(members)
			b.sort()
			stdin.append('{0}\t{1}\t{2}\t{3}'.format(keyFlock, begin, end, b))
			keyFlock += 1
	
	return stdin
			
def main():
	t1 = time.time()
	global traj
	global stdin
	
	bfe.epsilon = 40
	bfe.mu = 3
	bfe.delta = 3
	bfe.precision = 0.001
	file = 'SD1300T100t.csv'
	
	dataset = csv.reader(open(file, 'r'),delimiter='\t')
	output = open('output.dat','w')
	db = pdbc.DBConnector()
	db.resetTable('flock{0}lcm'.format(file))
	
	next(dataset)
		
	points = bfe.pointTimestamp(dataset)
	
	timestamps = list(points.keys())
	timestamps.sort()
	
	previousFlocks = []
	keyFlock = 1
	diskID = 1
	
	traj = {}
	totalMaximalDisks = {}
	stdin = []
	
	for timestamp in range(int(timestamps[0]),int(timestamps[0])+len(timestamps)):
		centersDiskCompare, treeCenters, disksTime = bfe.disksTimestamp(points, timestamp)	
		if centersDiskCompare == 0:
			continue
		#print(timestamp, len(centersDiskCompare))
		maximalDisks, diskID = bfe.maximalDisksTimestamp(centersDiskCompare, treeCenters,disksTime, timestamp, diskID)
		totalMaximalDisks.update(maximalDisks)
		
		getTransactions(points, timestamp, maximalDisks)
	
	for i in traj:
		if len(traj[i]) == 1:
			continue
		output.write(str(traj[i]).replace(',','').replace('[','').replace(']','')+'\n')
	
	output.close()
	os.system("./fim_closed output.dat " + str(bfe.mu) + " output.mfi")
	output1 = open('output.mfi','r')	
	
	keyFlock = 1
	stdin = flocks(output1, totalMaximalDisks, keyFlock)
	
	
	stdin = '\n'.join(stdin)
	db.copyToTable('flock{0}lcm'.format(file),io.StringIO(stdin))
	
	t2 = time.time()-t1
	print("\nTime: ",t2)
	return 0

if __name__ == '__main__':
	main()
