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

import bfe
import time
import csv
import os

def getTransactions(points, timestamp, maximalDisks):
	for maximal in maximalDisks:
		for member in maximalDisks[maximal].members:
			if not member  in traj.keys():
				traj[member]= []
				traj[member].append(maximalDisks[maximal].id)
			else:
				traj[member].append(maximalDisks[maximal].id)
	return traj
	
def main():
	t1 = time.time()
	global traj
	
	bfe.epsilon = 200
	bfe.mu = 3
	bfe.delta = 3
	bfe.precision = 0.001

	dataset = csv.reader(open('Oldenburg.csv', 'r'),delimiter='\t')
	output = open('output.dat','w')

	next(dataset)
		
	points = bfe.pointTimestamp(dataset)
	
	timestamps = list(points.keys())
	timestamps.sort()
	
	previousFlocks = []
	keyFlock = 1
	diskID = 1
	
	traj = {}
	totalMaximalDisks = {}
	
	for timestamp in range(int(timestamps[0]),int(timestamps[0])+len(timestamps)):
		centersDiskCompare, treeCenters, disksTime = bfe.disksTimestamp(points, timestamp)	
		if centersDiskCompare == 0:
			continue
		#print(timestamp, len(centersDiskCompare))
		maximalDisks, diskID = bfe.maximalDisksTimestamp(centersDiskCompare, treeCenters,disksTime, timestamp, diskID)
		totalMaximalDisks.update(maximalDisks)
		
		getTransactions(points, timestamp, maximalDisks)
	
	for i in traj:
		if len(traj[i])>1:
			output.write(str(traj[i]).replace(',','').replace('[','').replace(']','')+'\n')
	
	output.close()
	os.system("./fim_maximal output.dat 3 output.mfi")
	output1 = open('output.mfi','r')	
	
	t2 = time.time()-t1
	print("\nTime: ",t2)
	return 0

if __name__ == '__main__':
	main()
