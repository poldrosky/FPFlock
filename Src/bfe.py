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
import math
import time
import copy

global epsilon
global mu
global delta
global precision
global output

class Index(object):
	def __init__(self,x,y):
		self.x = x
		self.y = y
		
	def __str__ (self):
		return "%s %s" % (self.x, self.y)	

	
class Point(object):
	def __init__(self, *args):
		if len(args) == 4:
			self.id = int(args[0])
			self.time = int(args[1])
			self.x = float(args[2])
			self.y = float(args[3])
		
		elif len(args) == 2:
			self.x = float(args[0])
			self.y = float(args[1])
		else:
			raise SomeException()
		
	def getIndex(self):
		index = Index(int(self.x/epsilon), int(self.y/epsilon))
		return index
		
	def __str__(self):
		return "%s %s" % (self.x, self.y)
	

class Grid(object):
	def __init__(self,dictPoint):
		self.dictPoint = dictPoint
		
	def getPoints(self,indexGrid):
		try:
			return self.dictPoint[str(indexGrid)]
		except:
			return []
	
	def getFrame(self, point):
		points = []
		index = point.getIndex()
		a=index.x
		b=index.y
		points += Grid.getPoints(self,Index(a,b))
		points += Grid.getPoints(self,Index(a-1,b+1))
		points += Grid.getPoints(self,Index(a,b+1))
		points += Grid.getPoints(self,Index(a+1,b+1))
		points += Grid.getPoints(self,Index(a-1,b))
		points += Grid.getPoints(self,Index(a+1,b))
		points += Grid.getPoints(self,Index(a-1,b-1))
		points += Grid.getPoints(self,Index(a,b-1))
		points += Grid.getPoints(self,Index(a+1,b-1))
				
		if (len(points) >= mu):
			return points			
		else:
			return None
		

class Disk(object):
	def __init__(self,center, timestamp,members):
		self.id = str(center.x)+"-"+str(center.y)
		self.center = center
		self.members = members
		self.timestamp = timestamp
		self.valid = True
		
	def __str__(self):
		a = (str(self.center.x) +" "+ str(self.center.y))
		b = set()
		for i in self.members:
			b.add(str(i))
		return "%s %s" % (a,b)


class Flock(Disk):
	def __init__(self, disk, timestamp):
		self.disk = disk
		self.id = self.disk.id
		self.center = self.disk.center
		self.members  = self.disk.members
		self.diskFlock = [self.disk.id]
		self.start = timestamp
		self.end = timestamp
			
		
	def getDuration(self):
		return (self.end - self.start) + 1
		
	
	def __str__(self):
		return "%s %s" % (self.disk.id, self.disk.members)	
			

def calculateDisks(p1, p2):
	"""Calculate the center of the disk passing through two points"""
	r2 = math.pow(epsilon/2,2)
	disks = []
    
	p1_x = p1.x
	p1_y = p1.y
	p2_x = p2.x
	p2_y = p2.y
    
	X = p1_x - p2_x
	Y = p1_y - p2_y
	D2 = math.pow(X, 2) + math.pow(Y, 2)
    
	if (D2 == 0):
		return []

	expression = abs(4 * (r2 / D2) - 1)
	root = math.pow(expression, 0.5)
	h_1 = ((X + Y * root) / 2) + p2_x
	h_2 = ((X - Y * root) / 2) + p2_x
	k_1 = ((Y - X * root) / 2) + p2_y
	k_2 = ((Y + X * root) / 2) + p2_y

	disks.append(Point(h_1, k_1))
	disks.append(Point(h_2, k_2))
    
	return disks


def pointTimestamp(dataset):
	"""Receive dataset and return dictonary points per timestamp"""
	points={}
	for id, timestamp, latitude, longitude in dataset:
		if timestamp in points:
			points[timestamp].append(Point(id,timestamp,latitude,longitude))
		else:
			points[timestamp] = []
			points[timestamp].append(Point(id,timestamp,latitude,longitude))

	return points
	

def disksTimestamp(points, timestamp):
	"""Receive points per timestamp and return center disks compare, 
	nearest tree centers and disks per timestamp with yours members"""
	dictPoint={}
	disks = {}
	for point in points[str(timestamp)]:
		index = point.getIndex()
		if str(index) in dictPoint:
		    value = dictPoint[str(index)]
		    value.append(point)
		else:
			value=[]
			value.append(point)
			dictPoint[str(index)]= value
	
	grid=Grid(dictPoint)
	centersDiskCompare=[]
	
	for point in points[str(timestamp)]:
		pointsFrame = grid.getFrame(point)
		if (pointsFrame == None):
			continue
		
		frame = []
		
		for i in pointsFrame:
			frame.append((i.x,i.y))
			
		treeFrame = ss.cKDTree(frame)
		pointsNearestFrame = treeFrame.query_ball_point([point.x,point.y], epsilon+precision)

		for i in pointsNearestFrame:
			p2 = pointsFrame[i]
			if point == p2:
				continue
			centersDisk = calculateDisks(point, p2)
			
			for j in centersDisk:
				nearestCenter = treeFrame.query_ball_point([j.x,j.y], (epsilon/2)+precision)
				members = []
				
				for k in nearestCenter:
					members.append(pointsFrame[k].id)
				
				if len(members) < mu:
					continue
				centersDiskCompare.append((j.x,j.y))
				
				pKeyDisk = str(j.x)+"-"+str(j.y)
				if timestamp in disks:
					disks[timestamp][pKeyDisk] = Disk(j, timestamp, set(members))
				else:
					disks[timestamp] = {}
					disks[timestamp][pKeyDisk] = Disk(j, timestamp, set(members))
	
	if centersDiskCompare == []:
		return 0,0,0
 							
	centersDiskCompare = list(set(centersDiskCompare))
	treeCenters = ss.cKDTree(centersDiskCompare)
	disksTime = disks[timestamp]
	
	return (centersDiskCompare, treeCenters, disksTime)
				

def maximalDisksTimestamp(centersDiskCompare, treeCenters,disksTime, timestamp, diskID):
	"""This method return the maximal disks per timestamp"""
	maximalDisks = {}
	maximalDisks[timestamp] = {}
	
	for i in disksTime:
		if disksTime[i].valid:
			ce = treeCenters.query_ball_point([disksTime[i].center.x,disksTime[i].center.y], epsilon+precision)
			disksOverlapped = {}
			for l in ce:
				var= centersDiskCompare[l]
				var1=str(var[0])+"-"+str(var[1])
				if (disksTime[var1].valid):
					disksOverlapped[disksTime[var1].id] = disksTime[var1]
			
			c = list(disksOverlapped.keys())
			
			for j in range(len(c)):
				for k in range(j+1,len(c)):
					if  not c[j] in list(disksOverlapped.keys()):
						continue
						
					if  not c[k] in list(disksOverlapped.keys()):
						continue
					
					if(disksOverlapped[c[j]].members.issubset(disksOverlapped[c[k]].members)):
						disksTime[c[j]].valid = False
						del (disksOverlapped[c[j]])
						continue
						
					if(disksOverlapped[c[k]].members.issubset(disksOverlapped[c[j]].members)):
						disksTime[c[k]].valid = False
						del (disksOverlapped[c[k]])
						continue
						
	for d in disksTime:
		if disksTime[d].valid:
			disksTime[d].id = diskID
			maximalDisks[timestamp][disksTime[d].id] = disksTime[d]
			diskID += 1
	
	return (maximalDisks[timestamp], diskID)
	

def flocks(maximalDisks, previousFlocks, timestamp, keyFlock):
	"""Receive maximal disks, previous flocks, tiemstamp, key Flock 
	return previos flock and write file with flocks """
	currentFlocks = []
	for md in maximalDisks:
		for f in previousFlocks:
			inter = len(maximalDisks[md].members.intersection(f.members))
			if(inter>=mu):
				f1 = copy.copy(f)
				f1.members = maximalDisks[md].members.intersection(f1.members)
				f1.diskFlock.append(maximalDisks[md].id)
				f1.end = timestamp
												
				if f1.getDuration() == delta:
					b = list(f1.members)
					b.sort()
					output.writerow([keyFlock, f1.start, f1.end, b])
					keyFlock += 1
					f1.start = timestamp - delta + 1 
					
				if f1.start > timestamp  - delta:
					currentFlocks.append(f1)
										
		currentFlocks.append(Flock(maximalDisks[md],timestamp))
				
	previousFlocks = currentFlocks
	return (previousFlocks, keyFlock)
	
	
def main():
	t1 = time.time()
	global epsilon
	global mu
	global delta
	global precision
	global output
	
	epsilon = 50
	mu = 3
	delta = 3
	precision = 0.001

	dataset = csv.reader(open('syntheticdata.csv', 'r'),delimiter='\t')
	output = csv.writer(open('flocksBfe.csv', 'w', newline=''), delimiter='\t')

	next(dataset)
		
	points = pointTimestamp(dataset)
	
	timestamps = list(points.keys())
	timestamps.sort()
	
	previousFlocks = []
	keyFlock = 1
	diskID = 1
		
	for timestamp in range(int(timestamps[0]),int(timestamps[0])+len(timestamps)):
		centersDiskCompare, treeCenters, disksTime = disksTimestamp(points, timestamp)	
		if centersDiskCompare == 0:
			continue
		#print(timestamp, len(centersDiskCompare))
		maximalDisks, diskID = maximalDisksTimestamp(centersDiskCompare, treeCenters,disksTime, timestamp, diskID)
		#print("Maximal",len(maximalDisks))
		previousFlocks, keyFlock = flocks(maximalDisks, previousFlocks, timestamp, keyFlock)
	t2 = time.time()-t1
	print("\nTime: ",t2)
	return 0

if __name__ == '__main__':
	main()
